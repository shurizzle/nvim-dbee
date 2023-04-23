local M = {}

---@return { string: string } helpers list of table helpers
local function postgres()
  local basic_constraint_query = [[
    SELECT tc.constraint_name, tc.table_name, kcu.column_name, ccu.table_name AS foreign_table_name, ccu.column_name AS foreign_column_name, rc.update_rule, rc.delete_rule
    FROM
         information_schema.table_constraints AS tc
         JOIN information_schema.key_column_usage AS kcu
           ON tc.constraint_name = kcu.constraint_name
         JOIN information_schema.referential_constraints as rc
           ON tc.constraint_name = rc.constraint_name
         JOIN information_schema.constraint_column_usage AS ccu
           ON ccu.constraint_name = tc.constraint_name ]]

  return {
    List = 'select * from "{table}" LIMIT 500',
    Columns = "select * from information_schema.columns where table_name='{table}' and table_schema='{schema}'",
    Indexes = "SELECT * FROM pg_indexes where tablename='{table}' and schemaname='{schema}'",
    ["Foreign Keys"] = basic_constraint_query
      .. "WHERE constraint_type = 'FOREIGN KEY' and tc.table_name = '{table}' and tc.table_schema = '{schema}'",
    References = basic_constraint_query
      .. "WHERE constraint_type = 'FOREIGN KEY' and ccu.table_name = '{table}' and tc.table_schema = '{schema}'",
    ["Primary Keys"] = basic_constraint_query
      .. "WHERE constraint_type = 'PRIMARY KEY' and tc.table_name = '{table}' and tc.table_schema = '{schema}'",
  }
end

---@return { string: string } helpers list of table helpers
local function mysql()
  return {
    List = "SELECT * from `{table}` LIMIT 500",
    Columns = "DESCRIBE `{table}`",
    Indexes = "SHOW INDEXES FROM `{table}`",
    ["Foreign Keys"] = "SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA = '{schema}' AND TABLE_NAME = '{table}' AND CONSTRAINT_TYPE = 'FOREIGN KEY'",
    ["Primary Keys"] = "SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA = '{schema}' AND TABLE_NAME = '{table}' AND CONSTRAINT_TYPE = 'PRIMARY KEY'",
  }
end

---@return { string: string } helpers list of table helpers
local function sqlite()
  return {
    List = 'select * from "{table}" LIMIT 500',
    Indexes = "SELECT * FROM pragma_index_list('{table}')",
    ["Foreign Keys"] = "SELECT * FROM pragma_foreign_key_list('{table}')",
    ["Primary Keys"] = "SELECT * FROM pragma_index_list('{table}') WHERE origin = 'pk'",
  }
end

---@return { string: string } helpers list of table helpers
local function redis()
  return {
    List = "KEYS *",
  }
end

---@param type string
---@return { string: string } helpers list of table helpers
function M.get(type)
  if type == "postgres" then
    return postgres()
  elseif type == "mysql" then
    return mysql()
  elseif type == "sqlite" then
    return sqlite()
  elseif type == "redis" then
    return redis()
  end
  error("unsupported table type for helpers: " .. type)
  return {}
end

---@param unexpanded_query string
---@param vars { table: string, schema: string, dbname: string }
---@return string query with expanded vars
function M.expand_query(unexpanded_query, vars)
  local ret = unexpanded_query
  for key, val in pairs(vars) do
    ret = ret:gsub("{" .. key .. "}", val)
  end
  return ret
end

return M
