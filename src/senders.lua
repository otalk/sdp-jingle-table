local M = {}

M.initiator = {
    incoming = {
        initiator = "recvonly",
        responder = "sendonly",
        both = "sendrecv",
        none = "inactive",
        recvonly = "initiator",
        sendonly = "responder",
        sendrecv = "both",
        inactive = "none"
    },
    outgoing = {
        initiator = "sendonly",
        responder = "recvonly",
        both = "sendrecv",
        none = "inactive",
        recvonly = "responder",
        sendonly = "initiator",
        sendrecv = "both",
        inactive = "none"
    }
}

M.responder = {
    incoming = {
        initiator = "sendonly",
        responder = "recvonly",
        both = "sendrecv",
        none = "inactive",
        recvonly = "responder",
        sendonly = "initiator",
        sendrecv = "both",
        inactive = "none"
    },
    outgoing = {
        initiator = "recvonly",
        responder = "sendonly",
        both = "sendrecv",
        none = "inactive",
        recvonly = "initiator",
        sendonly = "responder",
        sendrecv = "both",
        inactive = "none"
    }
}

return M
