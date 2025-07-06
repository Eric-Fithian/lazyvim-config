-- print("💥 venv-selector.lua loaded")
-- ~/.config/nvim/lua/plugins/venv-selector.lua
-- Virtual environment management for LazyVim (Regexp branch version)
return {
    {
        "linux-cultist/venv-selector.nvim",
        dependencies = {
            "neovim/nvim-lspconfig",
            { "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } },
        },
        lazy = false,
        branch = "regexp", -- This is the regexp branch, use this for the new version
        main = "venv-selector",
        config = function()
            -- print("venv-selector config loaded")
            require("venv-selector").setup({
                options = {
                    -- on_venv_activate_callback = nil, -- callback function for after a venv activates
                    enable_default_searches = true, -- switches all default searches on/off
                    enable_cached_venvs = true, -- use cached venvs that are activated automatically when a python file is registered with the LSP.
                    cached_venv_automatic_activation = true, -- if set to false, the VenvSelectCached command becomes available to manually activate them.
                    activate_venv_in_terminal = true, -- activate the selected python interpreter in terminal windows opened from neovim
                    set_environment_variables = true, -- sets VIRTUAL_ENV or CONDA_PREFIX environment variables
                    notify_user_on_venv_activation = true, -- notifies user on activation of the virtual env
                    search_timeout = 5, -- if a search takes longer than this many seconds, stop it and alert the user
                    debug = true, -- enables you to run the VenvSelectLog command to view debug logs
                    fd_binary_name = "fd",
                    require_lsp_activation = true, -- require activation of an lsp before setting env variables

                    -- telescope viewer options
                    on_telescope_result_callback = nil, -- callback function for modifying telescope results
                    show_telescope_search_type = true, -- shows which of the searches found which venv in telescope
                    telescope_filter_type = "substring", -- when you type something in telescope, filter by "substring" or "character"
                    telescope_active_venv_color = "#00FF00", -- The color of the active venv in telescope
                    picker = "auto", -- The picker to use. Valid options are "telescope", "fzf-lua", "native", or "auto"
                },
                search = {
                    my_home_venvs = {
                        command = "find ~/venvs -name python 2>/dev/null",
                    },
                },
            })
        end,
        keys = {
            { "<leader>vs", "<cmd>VenvSelect<cr>", desc = "Select Virtual Environment" },
            { "<leader>vc", "<cmd>VenvSelectCached<cr>", desc = "Select Cached Virtual Environment" },
            {
                "<leader>vn",
                function()
                    local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
                    vim.ui.input({
                        prompt = "Environment name: ",
                        default = project_name,
                    }, function(venv_name)
                        if not venv_name or venv_name == "" then
                            return
                        end
                        local venv_path = vim.fn.expand("~/venvs/" .. venv_name)
                        if vim.fn.isdirectory(venv_path) == 1 then
                            vim.notify("❌ Environment already exists: " .. venv_name, vim.log.levels.WARN)
                            return
                        end
                        -- Ensure ~/venvs directory exists
                        vim.fn.mkdir(vim.fn.expand("~/venvs"), "p")
                        vim.notify("🔨 Creating virtual environment: " .. venv_name .. "...")
                        vim.fn.jobstart({ "python3", "-m", "venv", venv_path }, {
                            on_exit = function(_, exit_code)
                                if exit_code == 0 then
                                    vim.notify("✅ Created environment: " .. venv_name, vim.log.levels.INFO)
                                    vim.defer_fn(function()
                                        vim.cmd("VenvSelectCached")
                                    end, 1500)
                                else
                                    vim.notify("❌ Failed to create environment: " .. venv_name, vim.log.levels.ERROR)
                                end
                            end,
                        })
                    end)
                end,
                desc = "Create New Virtual Environment",
            },
            {
                "<leader>vp",
                function()
                    local venv_selector = require("venv-selector")
                    local venv_path = venv_selector.venv()
                    if not venv_path or venv_path == "" then
                        vim.notify("❌ No virtual environment active. Select one with <leader>vs", vim.log.levels.WARN)
                        return
                    end
                    local venv_name = vim.fn.fnamemodify(venv_path, ":t")
                    vim.ui.input({
                        prompt = "Packages to install: ",
                        default = "pandas matplotlib numpy",
                    }, function(packages)
                        if not packages or packages == "" then
                            return
                        end
                        -- Use pip from the selected environment
                        local pip_cmd = venv_path .. "/bin/pip"
                        if vim.fn.executable(pip_cmd) ~= 1 then
                            vim.notify("❌ pip not found at: " .. pip_cmd, vim.log.levels.ERROR)
                            return
                        end
                        vim.notify("📦 Installing packages in " .. venv_name .. ": " .. packages)
                        local package_list = vim.split(packages, "%s+")
                        local cmd = { pip_cmd, "install" }
                        for _, pkg in ipairs(package_list) do
                            if pkg ~= "" then
                                table.insert(cmd, pkg)
                            end
                        end
                        vim.fn.jobstart(cmd, {
                            on_stdout = function(_, data)
                                if data then
                                    for _, line in ipairs(data) do
                                        if line ~= "" and not line:match("^%s*$") then
                                            print("  " .. line)
                                        end
                                    end
                                end
                            end,
                            on_exit = function(_, exit_code)
                                if exit_code == 0 then
                                    vim.notify(
                                        "✅ Successfully installed packages in " .. venv_name,
                                        vim.log.levels.INFO
                                    )
                                    if _G.PythonRepl and _G.PythonRepl.repl_job then
                                        vim.notify(
                                            "💡 Restart REPL with <leader>rr to use new packages",
                                            vim.log.levels.INFO
                                        )
                                    end
                                else
                                    vim.notify("❌ Failed to install packages", vim.log.levels.ERROR)
                                end
                            end,
                        })
                    end)
                end,
                desc = "Install packages via pip into current venv",
            },
            {
                "<leader>vd",
                function()
                    local venv_selector = require("venv-selector")
                    local path = require("venv-selector.path")

                    -- Call the original deactivate logic
                    venv_selector.deactivate()

                    -- Manually clear internal plugin state (patch for bug in main plugin branch)
                    path.current_python_path = nil
                    path.current_venv_path = nil

                    -- Refresh the UI
                    require("lualine").refresh()
                    vim.cmd("redrawstatus") -- Optional but helpful

                    vim.notify("🔄 Deactivated virtual environment", vim.log.levels.INFO)
                end,
                desc = "Deactivate current virtual environment",
            },
            {
                "<leader>va",
                function()
                    local venv = require("venv-selector").venv()
                    if venv and venv ~= "" then
                        local activate_cmd = "source " .. venv .. "/bin/activate"
                        vim.cmd("ToggleTerm direction=horizontal")
                        vim.fn.feedkeys("i" .. activate_cmd .. "\n", "n")
                    else
                        vim.notify("No venv active", vim.log.levels.WARN)
                    end
                end,
                desc = "Activate venv in terminal",
            },
            -- DEBUG keybinding
            {
                "<leader>vm",
                function()
                    vim.cmd("VenvSelect find ~/venvs -name python 2>/dev/null")
                end,
                desc = "Manual venv select (working version)",
            },
            {
                "<leader>vt",
                function()
                    -- Test manual commands to see what's found
                    vim.notify("=== Testing venv detection ===", vim.log.levels.INFO)

                    -- Test if ~/venvs exists
                    local venvs_dir = vim.fn.expand("~/venvs")
                    vim.notify(
                        "~/venvs directory exists: " .. tostring(vim.fn.isdirectory(venvs_dir) == 1),
                        vim.log.levels.INFO
                    )
                    vim.notify("~/venvs path: " .. venvs_dir, vim.log.levels.INFO)

                    -- Test the working find commands
                    local commands = {
                        { "find ~/venvs -name python -type l 2>/dev/null", "Find symlinks" },
                        { "find ~/venvs -name python 2>/dev/null", "Find any python" },
                        { "find ~/venvs -name python3 -type f 2>/dev/null", "Find python3 files" },
                    }

                    for _, cmd_info in ipairs(commands) do
                        local handle = io.popen(cmd_info[1])
                        if handle then
                            local result = handle:read("*a")
                            handle:close()
                            vim.notify(cmd_info[2] .. " results:", vim.log.levels.INFO)
                            if result and result ~= "" then
                                vim.notify(result, vim.log.levels.INFO)
                            else
                                vim.notify("No results", vim.log.levels.WARN)
                            end
                        end
                        vim.defer_fn(function() end, 100) -- Small delay between commands
                    end

                    -- Test if fd is available
                    vim.notify("fd available: " .. tostring(vim.fn.executable("fd") == 1), vim.log.levels.INFO)
                    vim.notify("fdfind available: " .. tostring(vim.fn.executable("fdfind") == 1), vim.log.levels.INFO)
                end,
                desc = "Test venv detection",
            },
            {
                "<leader>vl",
                function()
                    -- View debug logs if available
                    vim.cmd("VenvSelectLog")
                end,
                desc = "View venv-selector debug logs",
            },
            {
                "<leader>vi",
                function()
                    local venv_selector = require("venv-selector")
                    local python_path = venv_selector.python()

                    if python_path and python_path ~= "" then
                        local venv_dir = vim.fn.fnamemodify(vim.fn.fnamemodify(python_path, ":h:h"), ":t")
                        vim.notify(
                            "🐍 Active Environment: " .. venv_dir .. "\n📍 Python Path: " .. python_path,
                            vim.log.levels.INFO
                        )
                    else
                        vim.notify("❌ No virtual environment active", vim.log.levels.WARN)
                    end
                end,
                desc = "Show Current Python Environment Info",
            },
        },
    },
    -- Status line integration
    {
        "nvim-lualine/lualine.nvim",
        optional = false,
        opts = function(_, opts)
            local function venv_status()
                local has_venv_selector, venv_selector = pcall(require, "venv-selector")
                if has_venv_selector then
                    local python_path = venv_selector.python()
                    if python_path and python_path ~= "" then
                        -- go up two levels: .../venvs/myenv/bin/python → "myenv"
                        local venv_name = vim.fn.fnamemodify(vim.fn.fnamemodify(python_path, ":h:h"), ":t")
                        return "🐍 (" .. venv_name .. ")"
                    else
                        return "🐍 (none)"
                    end
                end
                return "🐍 (none)"
            end
            table.insert(opts.sections.lualine_x, 1, {
                venv_status,
                color = { fg = "#8cc85f" },
            })
        end,
    },
}
