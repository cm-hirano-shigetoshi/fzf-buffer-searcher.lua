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
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local buf_name = get_buf_name(buf)
        if buf_name then
            local filepath = dirname .. "/" .. buf .. ":" .. buf_name
            os.execute("mkdir -p " .. filepath:match("(.*/)"))
            local file = io.open(filepath, "w")
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            for _, line in ipairs(lines) do
                file:write(line .. "\n")
            end
            file:close()
        end
    end
end

local function execute_fzf(dirname)
    coroutine.wrap(function(dirname)
        local result = fzf.fzf("(cd " .. dirname .. " && rg -n ^)", "--reverse --delimiter : --with-nth 2..")
        -- result is a list of lines that fzf returns, if the user has chosen
        if result then
            local sp = split(result[1], ":")
            vim.api.nvim_set_current_buf(tonumber(sp[1]))
            vim.api.nvim_win_set_cursor(0, { tonumber(sp[3]), 1 })
        end
        os.execute("rm -fr " .. dirname)
    end)(dirname)
end

M.run = function()
    local tmpdir = os.tmpname()
    dump_buffers(tmpdir)
    execute_fzf(tmpdir)
end

return M