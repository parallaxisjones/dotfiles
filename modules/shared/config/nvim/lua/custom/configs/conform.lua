local options = {
	formatters_by_ft = {
		lua = { "stylua" },
		go = { "goimports", "gofmt" },
		rust = { "rustfmt", lsp_format = "fallback" },
		python = function(bufnr)
			if require("conform").get_formatter_info("ruff_format", bufnr).available then
				return { "ruff_format" }
			else
				return { "isort", "black" }
			end
		end,
		typescript = { "prettier" },
		javascript = { "prettier" },
		css = { "prettier" },
		html = { "prettier" },
		json = { "prettier" },
		markdown = { "prettier" },
	},
	--
	-- adding same formatter for multiple filetypes can look too much work for some
	-- instead of the above code you could just use a loop! the config is just a table after all!

	format_on_save = {
		-- These options will be passed to conform.format()
		timeout_ms = 500,
		lsp_fallback = true,
	},
}

require("conform").setup(options)
