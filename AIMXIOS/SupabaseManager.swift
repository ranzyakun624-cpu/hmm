import Foundation
import Combine

/// Handles Supabase License Key Verification for SENS X IOS
final class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    @Published var supabaseURL: String = UserDefaults.standard.string(forKey: "supabase_url") ?? "https://zdtnrsafgamxfynfukev.supabase.co"
    @Published var supabaseAnonKey: String = UserDefaults.standard.string(forKey: "supabase_key") ?? "sb_publishable_qZiUH6kpDOgoHTmDFZyDuw_mwsoWE-q"
    
    @Published var isVerifying: Bool = false
    @Published var lastErrorMessage: String? = nil

    private init() {}

    func saveCredentials(url: String, anonKey: String) {
        self.supabaseURL = url
        self.supabaseAnonKey = anonKey
        UserDefaults.standard.set(url, forKey: "supabase_url")
        UserDefaults.standard.set(anonKey, forKey: "supabase_key")
    }

    /// Validates the key on Supabase. Expiry is enforced server-side; failures deny access.
    func verifyLicense(username: String, licenseKey: String, completion: @escaping (Bool, String) -> Void) {
        let trimmedKey = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedKey.isEmpty else {
            DispatchQueue.main.async {
                completion(false, "License key cannot be empty")
            }
            return
        }

        guard let baseURL = URL(string: supabaseURL),
              baseURL.scheme?.lowercased() == "https" else {
            DispatchQueue.main.async {
                completion(false, "Supabase URL must be a valid HTTPS URL")
            }
            return
        }

        let endpoint = baseURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent("rpc")
            .appendingPathComponent("verify_license")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 8.0
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["p_license_key": trimmedKey])

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error {
                    completion(false, "Could not verify license: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      let data else {
                    completion(false, "Invalid server response")
                    return
                }

                guard httpResponse.statusCode == 200 else {
                    completion(false, "Supabase verification failed (HTTP \(httpResponse.statusCode))")
                    return
                }

                do {
                    guard let result = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let isValid = result["valid"] as? Bool,
                          let reason = result["reason"] as? String else {
                        completion(false, "Invalid license verification response")
                        return
                    }

                    switch reason {
                    case "lifetime":
                        completion(isValid, isValid ? "Lifetime license verified" : "License is not active")
                    case "active":
                        let durationDays = result["duration_days"] as? Int
                        let durationLabel = durationDays.map { "\($0)-day license verified" } ?? "Timed license verified"
                        completion(isValid, isValid ? durationLabel : "License is not active")
                    case "expired":
                        completion(false, "License has expired")
                    case "inactive":
                        completion(false, "License is inactive")
                    case "not_found":
                        completion(false, "License key was not found")
                    case "invalid_key":
                        completion(false, "License key is invalid")
                    default:
                        completion(false, "License verification failed")
                    }
                } catch {
                    completion(false, "Could not read license verification response")
                }
            }
        }.resume()
    }
}

