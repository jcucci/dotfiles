local M = {}

---@class TestRecord
---@field key string The key of the test
---@field name string The name of the test
---@field status string The test status (unknown,passed/failed)
---@field message string? Optional error message
---@field path string The file path where the test is located
---@field line number The line number in the file
---@field stack_trace string? Optional stack trace for failures
---@field duration number? The duration of the test in milliseconds
local TestRecord = {}
TestRecord.__index = TestRecord

---@param name string
---@param path string
---@param line number
---@return TestRecord
function TestRecord.new(name, path, line)
    local self = setmetatable({}, TestRecord)
    self.key = path .. "." .. name
    self.name = name
    self.status = "unknown"
    self.path = path
    self.line = line
    self.message = nil
    self.stack_trace = nil
    self.duration = nil
    return self
end

local tests = {}

---@param key string
---@param result TestRecord
function M.set_test(key, result)
    tests[key] = result
end

---@param key string
---@return TestRecord|nil
function M.get_test(key)
    return tests[key]
end

--@return number
function M.get_total_count()
    local total = 0

    for _ in pairs(tests) do
        total = total + 1
    end

    return total
end

--@return number
function M.get_passed_count()
    local passed = 0

    for _, result in pairs(tests) do
        if result.status == "passed" then
            passed = passed + 1
        end
    end

    return passed
end

--@return number
function M.get_failed_count()
    local failed = 0

    for _, result in pairs(tests) do
        if result.status == "failed" then
            failed = failed + 1
        end
    end

    return failed
end

---@return table<string, TestRecord>
function M.get_all_results()
    return tests
end

function M.clear_results()
    tests = {}
end

---@param name string
---@param file_path string
---@param line_number number
---@return TestRecord
function M.create_test_result(name, file_path, line_number)
    return TestRecord.new(name, file_path, line_number)
end

---@param key string
---@param status string
---@param duration number
function M.set_result(key, status, duration)
    local result = tests[key]
    if result then
        result.status = status
        result.duration = duration
    end
end

---@param key string
---@param error_message string
---@param stack_trace string?
function M.set_error(key, status, error_message, stack_trace)
    local result = tests[key]
    if result then
        result.error_message = error_message
        result.stack_trace = stack_trace
    end
end

return M

