local _glowstone = {}

function _glowstone.lexing(file)
    local token_file = {}
    
    for i, v in ipairs(file) do
        token_file[i] = {
            {
                data = v,
                type = "ident",
                pos_first = 1,
                pos_last = #v
            }
        }
    end

    return token_file
end

function _glowstone.lex_line(index, arr)

    for i, v in ipairs(arr) do
        arr[i] = {
            data = v.data,
            type = "ident",
            pos_first = 1,
            pos_last = #v.data
        }
    end

end

return _glowstone