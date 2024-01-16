/******/ (() => { // webpackBootstrap
/******/ 	"use strict";
var __webpack_exports__ = {};

;// CONCATENATED MODULE: ./src/vault/fido2/content/messaging/message.ts
var MessageType;
(function (MessageType) {
    MessageType[MessageType["CredentialCreationRequest"] = 0] = "CredentialCreationRequest";
    MessageType[MessageType["CredentialCreationResponse"] = 1] = "CredentialCreationResponse";
    MessageType[MessageType["CredentialGetRequest"] = 2] = "CredentialGetRequest";
    MessageType[MessageType["CredentialGetResponse"] = 3] = "CredentialGetResponse";
    MessageType[MessageType["AbortRequest"] = 4] = "AbortRequest";
    MessageType[MessageType["AbortResponse"] = 5] = "AbortResponse";
    MessageType[MessageType["ErrorResponse"] = 6] = "ErrorResponse";
})(MessageType || (MessageType = {}));

;// CONCATENATED MODULE: ./src/vault/fido2/content/messaging/messenger.ts
var __awaiter = (undefined && undefined.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};

const SENDER = "bitwarden-webauthn";
/**
 * A class that handles communication between the page and content script. It converts
 * the browser's broadcasting API into a request/response API with support for seamlessly
 * handling aborts and exceptions across separate execution contexts.
 */
class Messenger {
    /**
     * Creates a messenger that uses the browser's `window.postMessage` API to initiate
     * requests in the content script. Every request will then create it's own
     * `MessageChannel` through which all subsequent communication will be sent through.
     *
     * @param window the window object to use for communication
     * @returns a `Messenger` instance
     */
    static forDOMCommunication(window) {
        const windowOrigin = window.location.origin;
        return new Messenger({
            postMessage: (message, port) => window.postMessage(message, windowOrigin, [port]),
            addEventListener: (listener) => window.addEventListener("message", (event) => {
                if (event.origin !== windowOrigin) {
                    return;
                }
                listener(event);
            }),
        });
    }
    constructor(broadcastChannel) {
        this.broadcastChannel = broadcastChannel;
        this.broadcastChannel.addEventListener((event) => __awaiter(this, void 0, void 0, function* () {
            var _a;
            if (this.handler === undefined) {
                return;
            }
            const message = event.data;
            const port = (_a = event.ports) === null || _a === void 0 ? void 0 : _a[0];
            if ((message === null || message === void 0 ? void 0 : message.SENDER) !== SENDER || message == null || port == null) {
                return;
            }
            const abortController = new AbortController();
            port.onmessage = (event) => {
                if (event.data.type === MessageType.AbortRequest) {
                    abortController.abort();
                }
            };
            try {
                const handlerResponse = yield this.handler(message, abortController);
                port.postMessage(Object.assign(Object.assign({}, handlerResponse), { SENDER }));
            }
            catch (error) {
                port.postMessage({
                    SENDER,
                    type: MessageType.ErrorResponse,
                    error: JSON.stringify(error, Object.getOwnPropertyNames(error)),
                });
            }
            finally {
                port.close();
            }
        }));
    }
    /**
     * Sends a request to the content script and returns the response.
     * AbortController signals will be forwarded to the content script.
     *
     * @param request data to send to the content script
     * @param abortController the abort controller that might be used to abort the request
     * @returns the response from the content script
     */
    request(request, abortController) {
        return __awaiter(this, void 0, void 0, function* () {
            const requestChannel = new MessageChannel();
            const { port1: localPort, port2: remotePort } = requestChannel;
            try {
                const promise = new Promise((resolve) => {
                    localPort.onmessage = (event) => resolve(event.data);
                });
                const abortListener = () => localPort.postMessage({
                    metadata: { SENDER },
                    type: MessageType.AbortRequest,
                });
                abortController === null || abortController === void 0 ? void 0 : abortController.signal.addEventListener("abort", abortListener);
                this.broadcastChannel.postMessage(Object.assign(Object.assign({}, request), { SENDER }), remotePort);
                const response = yield promise;
                abortController === null || abortController === void 0 ? void 0 : abortController.signal.removeEventListener("abort", abortListener);
                if (response.type === MessageType.ErrorResponse) {
                    const error = new Error();
                    Object.assign(error, JSON.parse(response.error));
                    throw error;
                }
                return response;
            }
            finally {
                localPort.close();
            }
        });
    }
}

;// CONCATENATED MODULE: ./src/vault/fido2/content/content-script.ts
var content_script_awaiter = (undefined && undefined.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};


function isFido2FeatureEnabled() {
    return new Promise((resolve) => {
        chrome.runtime.sendMessage({ command: "checkFido2FeatureEnabled" }, (response) => resolve(response.result));
    });
}
function getFromLocalStorage(keys) {
    return content_script_awaiter(this, void 0, void 0, function* () {
        return new Promise((resolve) => {
            chrome.storage.local.get(keys, (storage) => resolve(storage));
        });
    });
}
function isDomainExcluded() {
    var _a, _b;
    return content_script_awaiter(this, void 0, void 0, function* () {
        // TODO: This is code copied from `notification-bar.tsx`. We should refactor this into a shared function.
        // Look up the active user id from storage
        const activeUserIdKey = "activeUserId";
        let activeUserId;
        const activeUserStorageValue = yield getFromLocalStorage(activeUserIdKey);
        if (activeUserStorageValue[activeUserIdKey]) {
            activeUserId = activeUserStorageValue[activeUserIdKey];
        }
        // Look up the user's settings from storage
        const userSettingsStorageValue = yield getFromLocalStorage(activeUserId);
        const excludedDomains = (_b = (_a = userSettingsStorageValue[activeUserId]) === null || _a === void 0 ? void 0 : _a.settings) === null || _b === void 0 ? void 0 : _b.neverDomains;
        return excludedDomains && window.location.hostname in excludedDomains;
    });
}
function hasActiveUser() {
    return content_script_awaiter(this, void 0, void 0, function* () {
        const activeUserIdKey = "activeUserId";
        const activeUserStorageValue = yield getFromLocalStorage(activeUserIdKey);
        return activeUserStorageValue[activeUserIdKey] !== undefined;
    });
}
function isSameOriginWithAncestors() {
    try {
        return window.self === window.top;
    }
    catch (_a) {
        return false;
    }
}
function initializeFido2ContentScript() {
    const s = document.createElement("script");
    s.src = chrome.runtime.getURL("content/fido2/page-script.js");
    (document.head || document.documentElement).appendChild(s);
    const messenger = Messenger.forDOMCommunication(window);
    messenger.handler = (message, abortController) => content_script_awaiter(this, void 0, void 0, function* () {
        const requestId = Date.now().toString();
        const abortHandler = () => chrome.runtime.sendMessage({
            command: "fido2AbortRequest",
            abortedRequestId: requestId,
        });
        abortController.signal.addEventListener("abort", abortHandler);
        if (message.type === MessageType.CredentialCreationRequest) {
            return new Promise((resolve, reject) => {
                const data = Object.assign(Object.assign({}, message.data), { origin: window.location.origin, sameOriginWithAncestors: isSameOriginWithAncestors() });
                chrome.runtime.sendMessage({
                    command: "fido2RegisterCredentialRequest",
                    data,
                    requestId: requestId,
                }, (response) => {
                    if (response.error !== undefined) {
                        return reject(response.error);
                    }
                    resolve({
                        type: MessageType.CredentialCreationResponse,
                        result: response.result,
                    });
                });
            });
        }
        if (message.type === MessageType.CredentialGetRequest) {
            return new Promise((resolve, reject) => {
                const data = Object.assign(Object.assign({}, message.data), { origin: window.location.origin, sameOriginWithAncestors: isSameOriginWithAncestors() });
                chrome.runtime.sendMessage({
                    command: "fido2GetCredentialRequest",
                    data,
                    requestId: requestId,
                }, (response) => {
                    if (response.error !== undefined) {
                        return reject(response.error);
                    }
                    resolve({
                        type: MessageType.CredentialGetResponse,
                        result: response.result,
                    });
                });
            }).finally(() => abortController.signal.removeEventListener("abort", abortHandler));
        }
        return undefined;
    });
}
function run() {
    return content_script_awaiter(this, void 0, void 0, function* () {
        if ((yield hasActiveUser()) && (yield isFido2FeatureEnabled()) && !(yield isDomainExcluded())) {
            initializeFido2ContentScript();
        }
    });
}
run();

/******/ })()
;