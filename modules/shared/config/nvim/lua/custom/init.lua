-- local autocmd = vim.api.nvim_create_autocmd
-- require("oil").setup()
-- Auto resize panes when resizing nvim window
-- autocmd("VimResized", {
--   pattern = "*",
--   command = "tabdo wincmd =",
-- })
-- vim.o.foldmethod = "expr"
-- vim.o.foldexpr   = "nvim_treesitter#foldexpr()"  -- UFO will override this; it just ensures expr‐mode is on
vim.g.python3_host_prog = '/usr/bin/python3'
-- vim.g.python2_host_prog = 'path/to/python2'

-- nvim-treesitter (master) ships query predicate/directive handlers that read
-- `match[id]` as a single TSNode. Nvim 0.12 always passes TSNode[] regardless
-- of the legacy `all = false` opt, which crashes in get_node_text → node:range().
-- Re-register the affected handlers with a shim that takes the first node.
vim.api.nvim_create_autocmd('User', {
  pattern = 'LazyLoad',
  callback = function(args)
    if args.data ~= 'nvim-treesitter' then return end
    local query = vim.treesitter.query
    local opts = { force = true, all = false }

    local function first(match, id)
      local v = match[id]
      if type(v) == 'table' then return v[1] end
      return v
    end

    local html_script_type_languages = {
      importmap = 'json',
      module = 'javascript',
      ['application/ecmascript'] = 'javascript',
      ['text/ecmascript'] = 'javascript',
    }
    local non_filetype_aliases = {
      ex = 'elixir', pl = 'perl', sh = 'bash', uxn = 'uxntal', ts = 'typescript',
    }

    query.add_predicate('nth?', function(match, _, _, pred)
      local node = first(match, pred[2])
      local n = tonumber(pred[3])
      if node and node:parent() and node:parent():named_child_count() > n then
        return node:parent():named_child(n) == node
      end
      return false
    end, opts)

    query.add_predicate('is?', function(match, _, bufnr, pred)
      local locals = require('nvim-treesitter.locals')
      local node = first(match, pred[2])
      if not node then return true end
      local types = { unpack(pred, 3) }
      local _, _, kind = locals.find_definition(node, bufnr)
      return vim.tbl_contains(types, kind)
    end, opts)

    query.add_predicate('kind-eq?', function(match, _, _, pred)
      local node = first(match, pred[2])
      if not node then return true end
      local types = { unpack(pred, 3) }
      return vim.tbl_contains(types, node:type())
    end, opts)

    query.add_directive('set-lang-from-mimetype!', function(match, _, bufnr, pred, metadata)
      local node = first(match, pred[2])
      if not node then return end
      local val = vim.treesitter.get_node_text(node, bufnr)
      local configured = html_script_type_languages[val]
      if configured then
        metadata['injection.language'] = configured
      else
        local parts = vim.split(val, '/', {})
        metadata['injection.language'] = parts[#parts]
      end
    end, opts)

    query.add_directive('set-lang-from-info-string!', function(match, _, bufnr, pred, metadata)
      local node = first(match, pred[2])
      if not node then return end
      local alias = vim.treesitter.get_node_text(node, bufnr):lower()
      metadata['injection.language'] =
        vim.filetype.match({ filename = 'a.' .. alias })
        or non_filetype_aliases[alias]
        or alias
    end, opts)

    query.add_directive('downcase!', function(match, _, bufnr, pred, metadata)
      local id = pred[2]
      local node = first(match, id)
      if not node then return end
      local text = vim.treesitter.get_node_text(node, bufnr, { metadata = metadata[id] }) or ''
      if not metadata[id] then metadata[id] = {} end
      metadata[id].text = string.lower(text)
    end, opts)
  end,
})
