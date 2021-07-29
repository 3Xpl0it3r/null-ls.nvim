local u = require("null-ls.utils")
local s = require("null-ls.state")
local methods = require("null-ls.methods")
local generators = require("null-ls.generators")

local M = {}

local convert_range = function(diagnostic)
    local start_line = u.string.to_number_safe(diagnostic.row, 0, -1)
    local start_char = u.string.to_number_safe(diagnostic.col, 0)
    local end_line = u.string.to_number_safe(diagnostic.end_row, start_line, -1)
    -- default to end of line
    local end_char = u.string.to_number_safe(diagnostic.end_col, -1)

    return {
        start = { line = start_line, character = start_char },
        ["end"] = { line = end_line, character = end_char },
    }
end

local postprocess = function(diagnostic, params)
    diagnostic.range = convert_range(diagnostic)
    diagnostic.source = diagnostic.source or params.command or "null-ls"
end

M.handler = function(original_params)
    if not original_params.textDocument then
        return
    end
    local method, uri = original_params.method, original_params.textDocument.uri
    if method == methods.lsp.DID_CHANGE then
        s.clear_cache(uri)
    end

    if method == methods.lsp.DID_CLOSE then
        return
    end

    original_params.bufnr = vim.uri_to_bufnr(uri)
    generators.run_registered(
        u.make_params(original_params, methods.internal.DIAGNOSTICS),
        postprocess,
        function(diagnostics)
            vim.lsp.handlers[methods.lsp.PUBLISH_DIAGNOSTICS](nil, nil, {
                diagnostics = diagnostics,
                uri = uri,
            }, original_params.client_id, nil, {})
        end
    )
end

return M
