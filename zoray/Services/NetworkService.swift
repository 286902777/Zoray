import Foundation

typealias NetworkCompletion<T> = (Result<T, NetworkError>) -> Void

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum NetworkEnvironment {
    case debug
    case release

    static var current: NetworkEnvironment {
        #if DEBUG
        return .debug
        #else
        return .release
        #endif
    }

    var baseURL: URL {
        switch self {
        case .debug:
            // Debug and Release hosts are separated here for future changes.
            return URL(string: "https://opi.cphub.link/")!
        case .release:
            return URL(string: "https://opi.cphub.link/")!
        }
    }
}

enum NetworkError: LocalizedError {
    case invalidURL(String)
    case emptyResponse
    case invalidParameters
    case decodingFailed(Error)
    case serverError(statusCode: Int, message: String?)
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let path):
            return "Invalid request URL: \(path)"
        case .emptyResponse:
            return "The server returned an empty response."
        case .invalidParameters:
            return "Invalid request parameters."
        case .decodingFailed:
            return "Failed to parse the server response."
        case .serverError(let statusCode, let message):
            return message ?? "Request failed with status code \(statusCode)."
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}

final class NetworkService {
    static let shared = NetworkService()

    let environment: NetworkEnvironment

    private let session: URLSession
    private let decoder: JSONDecoder
    private let callbackQueue: DispatchQueue

    var baseURL: URL {
        environment.baseURL
    }

    init(
        environment: NetworkEnvironment = .current,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        callbackQueue: DispatchQueue = .main
    ) {
        self.environment = environment
        self.session = session
        self.decoder = decoder
        self.callbackQueue = callbackQueue
    }

    @discardableResult
    func get<T: Decodable>(
        _ path: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        completion: @escaping NetworkCompletion<T>
    ) -> URLSessionDataTask? {
        request(
            path,
            method: .get,
            parameters: parameters,
            headers: headers,
            completion: completion
        )
    }

    @discardableResult
    func post<T: Decodable>(
        _ path: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        completion: @escaping NetworkCompletion<T>
    ) -> URLSessionDataTask? {
        request(
            path,
            method: .post,
            parameters: parameters,
            headers: headers,
            completion: completion
        )
    }

    @discardableResult
    func request<T: Decodable>(
        _ path: String,
        method: HTTPMethod = .get,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        completion: @escaping NetworkCompletion<T>
    ) -> URLSessionDataTask? {
        let result = makeRequest(path, method: method, parameters: parameters, headers: headers)
        switch result {
        case .success(let request):
            let task = session.dataTask(with: request) { data, response, error in
                self.handleResponse(data: data, response: response, error: error, completion: completion)
            }
            task.resume()
            return task
        case .failure(let error):
            complete(.failure(error), completion: completion)
            return nil
        }
    }

    @discardableResult
    func requestData(
        _ path: String,
        method: HTTPMethod = .get,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        completion: @escaping NetworkCompletion<Data>
    ) -> URLSessionDataTask? {
        let result = makeRequest(path, method: method, parameters: parameters, headers: headers)
        switch result {
        case .success(let request):
            let task = session.dataTask(with: request) { data, response, error in
                self.handleDataResponse(data: data, response: response, error: error, completion: completion)
            }
            task.resume()
            return task
        case .failure(let error):
            complete(.failure(error), completion: completion)
            return nil
        }
    }

    private func makeURL(_ path: String) -> URL? {
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else { return baseURL }

        if let absoluteURL = URL(string: trimmedPath), absoluteURL.scheme != nil {
            return absoluteURL
        }

        return URL(string: trimmedPath, relativeTo: baseURL)?.absoluteURL
    }

    private func makeRequest(
        _ path: String,
        method: HTTPMethod,
        parameters: [String: Any]?,
        headers: [String: String]?
    ) -> Result<URLRequest, NetworkError> {
        guard let url = makeURL(path) else {
            return .failure(.invalidURL(path))
        }

        var requestURL = url
        if method == .get, let parameters {
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return .failure(.invalidURL(path))
            }
            let existingItems = components.queryItems ?? []
            components.queryItems = existingItems + makeQueryItems(from: parameters)
            guard let urlWithQuery = components.url else {
                return .failure(.invalidParameters)
            }
            requestURL = urlWithQuery
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        if method != .get, let parameters {
            guard JSONSerialization.isValidJSONObject(parameters),
                  let body = try? JSONSerialization.data(withJSONObject: parameters) else {
                return .failure(.invalidParameters)
            }
            let jsonInfo = String(data: body, encoding: .utf8)
            guard let jsonAes = try? AESHelper.encrypt(jsonInfo ?? ""), let resultBody = jsonAes.data(using: .utf8) else {
                return .failure(.invalidParameters)
            }
            request.httpBody = resultBody
        }

        return .success(request)
    }

    private func makeQueryItems(from parameters: [String: Any]) -> [URLQueryItem] {
        parameters
            .sorted { $0.key < $1.key }
            .map { URLQueryItem(name: $0.key, value: "\($0.value)") }
    }

    private func handleResponse<T: Decodable>(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        completion: @escaping NetworkCompletion<T>
    ) {
        let dataResult: Result<Data, NetworkError> = validate(data: data, response: response, error: error)
        switch dataResult {
        case .success(let data):
            do {
                let value = try decoder.decode(T.self, from: data)
                complete(.success(value), completion: completion)
            } catch {
                complete(.failure(.decodingFailed(error)), completion: completion)
            }
        case .failure(let error):
            complete(.failure(error), completion: completion)
        }
    }

    private func handleDataResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        completion: @escaping NetworkCompletion<Data>
    ) {
        complete(validate(data: data, response: response, error: error), completion: completion)
    }

    private func validate(data: Data?, response: URLResponse?, error: Error?) -> Result<Data, NetworkError> {
        if let error {
            return .failure(.underlying(error))
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(.emptyResponse)
        }

        let responseData = data ?? Data()
        let statusCode = httpResponse.statusCode
        if !(200..<300).contains(statusCode) {
            return .failure(.serverError(statusCode: statusCode, message: serverMessage(from: responseData)))
        }

        guard !responseData.isEmpty else {
            return .failure(.emptyResponse)
        }

        return .success(responseData)
    }

    private func complete<T>(_ result: Result<T, NetworkError>, completion: @escaping NetworkCompletion<T>) {
        callbackQueue.async {
            completion(result)
        }
    }

    private func serverMessage(from data: Data?) -> String? {
        guard let data, !data.isEmpty else { return nil }

        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let message = jsonObject["message"] as? String {
                return message
            }
            if let error = jsonObject["error"] as? String {
                return error
            }
        }

        return String(data: data, encoding: .utf8)
    }
}
