local M = {}
local fzf = require("fzf")

require("fzf").default_options = {
    window_on_create = function()
        vim.cmd("set winhl=Normal:Normal")
    end
}

local function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

local function get_buf_name(buf)
    local fullpath = vim.api.nvim_buf_get_name(buf)
    if string.len(fullpath) > 0 then
        return vim.fn.fnamemodify(fullpath, ":~:.")
    else
        return nil
    end
end

local function dump_buffers(dirname)
    os.execute("rm -fr " .. dirname)
    for buf = 1, vim.fn.bufnr("$") do
        if vim.api.nvim_buf_is_valid(buf) then
            local buf_name = get_buf_name(buf)
            if buf_name then
                local filepath = dirname .. "/" .. buf .. ":" .. buf_name
                os.execute("mkdir -p " .. filepath:match("(.*/)"))
                if vim.api.nvim_buf_is_loaded(buf) then
                    local file = assert(io.open(filepath, "w"))
                    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
                    for _, line in ipairs(lines) do
                        file:write(line .. "\n")
                    end
                    file:close()
                else
                    os.execute("ln -s " .. vim.api.nvim_buf_get_name(buf) .. " " .. filepath)
                end
            end
        end
    end
end

local function execute_fzf(dirname_, query_)
    coroutine.wrap(function(dirname, query)
        local result = fzf.fzf("(cd " .. dirname .. " && rg --color always -L -n ^)",
            "--ansi --reverse --delimiter : --with-nth 2.. --query '" .. query .. " ' " ..
            "--preview '(cd " .. dirname .. " && bat --plain --number --color always --highlight-line {3} {..2})' " ..
            "--preview-window 'down:60%' --preview-window '+{3}+1/2'")
        if result then
            local sp = split(result[1], ":")
            vim.api.nvim_set_current_buf(tonumber(sp[1]))
            vim.api.nvim_win_set_cursor(0, { tonumber(sp[3]), 0 })
        end
        os.execute("rm -fr " .. dirname)
    end)(dirname_, query_)
end

local function call(query)
    local tmpdir = os.tmpname()
    dump_buffers(tmpdir)
    execute_fzf(tmpdir, query)
end

M.run = function(query)
    call(query)
end

return M
