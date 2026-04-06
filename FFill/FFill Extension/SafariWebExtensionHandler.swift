//
//  SafariWebExtensionHandler.swift
//  FFill Extension
//
//  Handles native messages from the Safari Web Extension.
//  Receives { action: "getFormData" } and responds with all FormItems and Folders
//  read from the shared SwiftData store via ExtensionDataService.
//
//  NOTE: beginRequest runs on a background thread. ExtensionDataService creates
//  a fresh ModelContext per call — never share a ModelContext across threads.
//

import SafariServices
import os.log

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem
        let message = request?.userInfo?[SFExtensionMessageKey] as? [String: Any]

        os_log(.default, "FFill Extension received message: %@", String(describing: message))

        guard let action = message?["action"] as? String, action == "getFormData" else {
            complete(context: context, success: false, error: "Unknown or missing action")
            return
        }

        do {
            let payload = try ExtensionDataService.buildResponsePayload()
            complete(context: context, success: true, data: payload)
        } catch {
            os_log(.error, "FFill Extension failed to fetch data: %@", error.localizedDescription)
            complete(context: context, success: false, error: error.localizedDescription)
        }
    }

    // MARK: - Helpers

    private func complete(
        context: NSExtensionContext,
        success: Bool,
        data: [String: Any]? = nil,
        error: String? = nil
    ) {
        var responseMessage: [String: Any] = ["success": success]
        if let data { responseMessage["data"] = data }
        if let error { responseMessage["error"] = error }

        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: responseMessage]
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }
}
