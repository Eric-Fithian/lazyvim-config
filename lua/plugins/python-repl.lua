-- ~/.config/nvim/lua/plugins/python-repl.lua
-- IPython REPL integration for LazyVim

return {
    {
        "python-repl",
        dir = ".", -- This is a local "plugin" (just configuration)
        lazy = false,
        config = function()
            local M = {}

            -- State
            M.repl_buf = nil
            M.repl_win = nil
            M.repl_job = nil

            -- Get script directory path
            local function get_script_dir()
                local config_dir = vim.fn.stdpath("config")
                return config_dir .. "/scripts/python-repl"
            end

            -- Ensure script directory exists
            local function ensure_script_dir()
                local script_dir = get_script_dir()
                vim.fn.mkdir(script_dir, "p")
                return script_dir
            end

            -- Get active Python from venv-selector
            local function get_active_python()
                local has_venv_selector, venv_selector = pcall(require, "venv-selector")
                if has_venv_selector then
                    local python_path = venv_selector.python()
                    if python_path and python_path ~= "" then
                        return python_path
                    end
                end
                return "python3"
            end

            -- Check if IPython is available
            local function check_ipython_available()
                local python_cmd = get_active_python()
                local handle = io.popen(python_cmd .. " -c 'import IPython; print(IPython.__version__)' 2>/dev/null")
                local result = handle:read("*a")
                handle:close()
                return result ~= ""
            end

            -- Get active venv name for display
            local function get_active_venv_name()
                local has_venv_selector, venv_selector = pcall(require, "venv-selector")
                if has_venv_selector then
                    local venv_path = venv_selector.venv()
                    if venv_path and venv_path ~= "" then
                        return vim.fn.fnamemodify(venv_path, ":t")
                    end
                end
                return "system"
            end

            -- Check if startup script exists
            local function ensure_startup_script()
                local script_dir = ensure_script_dir()
                local startup_script = script_dir .. "/startup_ipython.py"

                if vim.fn.filereadable(startup_script) == 0 then
                    vim.notify(
                        "⚠️  Missing startup script: startup_ipython.py" .. "\nCreate it in: " .. script_dir,
                        vim.log.levels.WARN
                    )
                    return false
                end

                return true
            end

            -- Helper function to get visual selection text
            local function get_visual_selection()
                local region = vim.region(0, "'<", "'>", vim.fn.visualmode(), true)
                local lines = {}
                for line_num, cols in pairs(region) do
                    local line = vim.api.nvim_buf_get_lines(0, line_num, line_num + 1, false)[1]
                    if cols[1] == cols[2] then
                        -- Whole line
                        table.insert(lines, line)
                    else
                        -- Partial line
                        table.insert(lines, line:sub(cols[1] + 1, cols[2]))
                    end
                end
                return table.concat(lines, "\n")
            end

            -- Start REPL
            function M.start_repl()
                if M.repl_job then
                    vim.notify("🐍 IPython REPL already running", vim.log.levels.INFO)
                    return
                end

                -- Check if IPython is available
                if not check_ipython_available() then
                    vim.notify("❌ IPython not available. Install with: pip install ipython", vim.log.levels.ERROR)
                    return
                end

                -- Ensure startup script exists
                if not ensure_startup_script() then
                    vim.notify("❌ Cannot start REPL without startup script", vim.log.levels.ERROR)
                    return
                end

                local python_cmd = get_active_python()
                local venv_name = get_active_venv_name()
                local script_dir = get_script_dir()

                -- Create vertical split (40% width)
                vim.cmd("vsplit")
                vim.cmd("wincmd l")
                vim.cmd("enew")
                vim.cmd("vertical resize 70%")

                -- Create terminal with IPython
                M.repl_job = vim.fn.termopen(python_cmd .. " -m IPython", {
                    env = {
                        KITTY_WINDOW_ID = "1",
                        TERM = "xterm-kitty",
                        TERMINAL_EMULATOR = "kitty",
                    },
                    on_exit = function()
                        M.repl_job = nil
                        M.repl_buf = nil
                        M.repl_win = nil
                    end,
                })

                M.repl_buf = vim.api.nvim_get_current_buf()
                M.repl_win = vim.api.nvim_get_current_win()

                -- Send startup script using %run magic command
                vim.defer_fn(function()
                    if M.repl_job then
                        local startup_script_path = script_dir .. "/startup_ipython.py"

                        -- Use IPython's %run magic command which properly sets __file__
                        local run_command = string.format("%%run %s %s\n", startup_script_path, venv_name)

                        vim.fn.jobsend(M.repl_job, run_command)
                    end
                end, 3000) -- Longer delay for IPython startup

                -- Return to main window
                vim.cmd("wincmd h")

                vim.notify("🚀 IPython REPL started: " .. venv_name, vim.log.levels.INFO)
            end

            -- Stop REPL
            function M.stop_repl()
                if M.repl_job then
                    M.focus_repl()
                    vim.cmd("wincmd q")
                    vim.fn.jobstop(M.repl_job)
                    vim.notify("🛑 IPython REPL stopped", vim.log.levels.INFO)
                else
                    vim.notify("❌ No REPL running", vim.log.levels.WARN)
                end
            end

            -- Restart REPL
            function M.restart_repl()
                M.stop_repl()
                vim.defer_fn(M.start_repl, 1000)
            end

            -- Send text to REPL
            function M.send_to_repl(text)
                if not M.repl_job then
                    vim.notify("❌ No REPL running. Start with <leader>rs", vim.log.levels.WARN)
                    return
                end

                -- Add newline if not present
                if not text:match("\n$") then
                    text = text .. "\n"
                end

                vim.fn.jobsend(M.repl_job, text)
            end

            -- Send current line
            function M.send_current_line()
                local line = vim.api.nvim_get_current_line()
                M.send_to_repl(line)
                vim.cmd("normal! j") -- Move to next line
            end

            -- Send visual selection
            function M.send_visual_selection()
                text = get_visual_selection()
                M.send_to_repl(text)
            end

            -- Send paragraph (code block separated by empty lines)
            function M.send_paragraph()
                local current_line = vim.fn.line(".")
                local start_line = current_line
                local end_line = current_line

                -- Find start of paragraph
                while start_line > 1 do
                    local line = vim.fn.getline(start_line - 1)
                    if line:match("^%s*$") then
                        break
                    end
                    start_line = start_line - 1
                end

                -- Find end of paragraph
                local total_lines = vim.fn.line("$")
                while end_line < total_lines do
                    local line = vim.fn.getline(end_line + 1)
                    if line:match("^%s*$") then
                        break
                    end
                    end_line = end_line + 1
                end

                local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
                local text = table.concat(lines, "\n")
                M.send_to_repl(text)
            end

            -- Send entire file
            function M.send_file()
                local current_file = vim.api.nvim_buf_get_name(0)
                if current_file and current_file ~= "" then
                    -- Use %run magic command for files
                    local run_command = string.format("%%run %s\n", current_file)
                    M.send_to_repl(run_command)
                    vim.notify(
                        "📄 Running file in REPL: " .. vim.fn.fnamemodify(current_file, ":t"),
                        vim.log.levels.INFO
                    )
                else
                    vim.notify("❌ Current buffer has no file", vim.log.levels.WARN)
                end
            end

            -- Focus REPL
            function M.focus_repl()
                if M.repl_win and vim.api.nvim_win_is_valid(M.repl_win) then
                    vim.api.nvim_set_current_win(M.repl_win)
                else
                    vim.notify("❌ No REPL window found", vim.log.levels.WARN)
                end
            end

            -- Clear REPL
            function M.clear_repl()
                if M.repl_job then
                    vim.fn.jobsend(M.repl_job, "%clear\n") -- Use IPython magic command
                    vim.notify("🧹 REPL cleared", vim.log.levels.INFO)
                else
                    vim.notify("❌ No REPL running", vim.log.levels.WARN)
                end
            end

            -- Send magic command
            function M.send_magic_command()
                local magic_commands = {
                    "%timeit ",
                    "%run ",
                    "%debug",
                    "%who",
                    "%whos",
                    "%matplotlib inline",
                    "%load_ext autoreload",
                    "%autoreload 2",
                    "%pdb on",
                    "%pdb off",
                    "%history",
                    "%reset",
                    "%clear",
                    "%pwd",
                    "%cd ",
                    "%ls",
                    "%quickref",
                }

                vim.ui.select(magic_commands, {
                    prompt = "Select IPython magic command:",
                }, function(choice)
                    if choice then
                        M.send_to_repl(choice)
                    end
                end)
            end

            -- Run external Python script using %run
            function M.run_script()
                local script_path = vim.fn.input("Script path: ", "", "file")
                if script_path and script_path ~= "" then
                    local run_command = string.format("%%run %s\n", script_path)
                    M.send_to_repl(run_command)
                    vim.notify("📜 Running script: " .. script_path, vim.log.levels.INFO)
                end
            end

            -- Edit startup script
            function M.edit_startup_script()
                local script_dir = ensure_script_dir()
                local startup_script = script_dir .. "/startup_ipython.py"
                vim.cmd("edit " .. startup_script)
            end

            -- Time current line/selection
            function M.timeit_current()
                local line = vim.api.nvim_get_current_line()
                local timeit_command = string.format("%%timeit %s\n", line)
                M.send_to_repl(timeit_command)
            end

            function M.timeit_selection()
                text = get_visual_selection()
                M.send_to_repl(timeit_command)
            end

            -- Reset REPL namespace
            function M.reset_repl()
                if M.repl_job then
                    vim.ui.select({ "Keep variables", "Reset all" }, {
                        prompt = "Reset IPython namespace:",
                    }, function(choice)
                        if choice == "Reset all" then
                            M.send_to_repl("%reset -f\n")
                            vim.notify("🔄 REPL namespace reset", vim.log.levels.INFO)
                        end
                    end)
                else
                    vim.notify("❌ No REPL running", vim.log.levels.WARN)
                end
            end

            -- Auto-restart REPL when venv changes
            vim.api.nvim_create_autocmd("User", {
                pattern = "VenvSelectPost",
                callback = function()
                    if M.repl_job then
                        vim.notify(
                            "🔄 Virtual environment changed. Restart REPL with <leader>rr",
                            vim.log.levels.INFO
                        )
                    end
                end,
            })

            -- Make functions available globally
            _G.PythonRepl = M
        end,
        keys = {
            -- REPL control
            {
                "<leader>rs",
                function()
                    _G.PythonRepl.start_repl()
                end,
                desc = "Start IPython REPL",
            },
            {
                "<leader>rq",
                function()
                    _G.PythonRepl.stop_repl()
                end,
                desc = "Stop REPL",
            },
            {
                "<leader>rr",
                function()
                    _G.PythonRepl.restart_repl()
                end,
                desc = "Restart REPL",
            },

            -- Code sending
            {
                "<leader><CR>",
                function()
                    _G.PythonRepl.send_current_line()
                end,
                desc = "Send current line to REPL",
                mode = "n",
            },
            {
                "<leader><CR>",
                function()
                    _G.PythonRepl.send_visual_selection()
                end,
                desc = "Send selection to REPL",
                mode = "v",
            },
            {
                "<S-CR>",
                function()
                    _G.PythonRepl.send_paragraph()
                end,
                desc = "Send paragraph to REPL",
                mode = "n",
            },
            {
                "<leader>rf",
                function()
                    _G.PythonRepl.send_file()
                end,
                desc = "Run current file in REPL",
            },

            -- REPL navigation and control
            {
                "<leader>ro",
                function()
                    _G.PythonRepl.focus_repl()
                end,
                desc = "Focus REPL",
            },
            {
                "<leader>rc",
                function()
                    _G.PythonRepl.clear_repl()
                end,
                desc = "Clear REPL",
            },
            {
                "<leader>rR",
                function()
                    _G.PythonRepl.reset_repl()
                end,
                desc = "Reset REPL namespace",
            },

            -- IPython magic commands
            {
                "<leader>rm",
                function()
                    _G.PythonRepl.send_magic_command()
                end,
                desc = "Send magic command",
            },
            {
                "<leader>rt",
                function()
                    _G.PythonRepl.timeit_current()
                end,
                desc = "Time current line",
                mode = "n",
            },
            {
                "<leader>rt",
                function()
                    _G.PythonRepl.timeit_selection()
                end,
                desc = "Time selection",
                mode = "v",
            },

            -- Script management
            {
                "<leader>rS",
                function()
                    _G.PythonRepl.run_script()
                end,
                desc = "Run external script",
            },
            {
                "<leader>re",
                function()
                    _G.PythonRepl.edit_startup_script()
                end,
                desc = "Edit startup script",
            },
        },
    },
}
