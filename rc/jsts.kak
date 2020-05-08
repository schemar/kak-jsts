# ╭────────────────╥────────────╮
# │ Author:        ║ File:      │
# │ Martin Schenck ║ jsts.kak   │
# ╞════════════════╩════════════╡
# │ JS/TS linting/formatting    │
# ╞═════════════════════════════╡
# │ github.com/schemar/kak-jsts │
# ╰─────────────────────────────╯

define-command format-eslint -docstring %{
    Formats the current buffer using eslint.
    Respects your local project setup in eslintrc.
} %{
    evaluate-commands -draft -no-hooks -save-regs '|' %{
        # Select all to format
        execute-keys '%'

        # eslint does a fix-dry-run with a json formatter which results in a JSON output to stdout that includes the fixed file.
        # jq then extracts the fixed file output from the JSON. -j returns the raw output without any escaping.
        set-register '|' %{
            %sh{
                echo "$kak_selection" | \
                npx eslint --format json \
                           --fix-dry-run \
                           --stdin \
                           --stdin-filename "$kak_buffile" | \
                jq -j ".[].output"
            }
        }

        # Replace all with content from register:
        execute-keys '|<ret>'
    }
}

define-command format-prettier -docstring %{
    Formats the current buffer using prettier.
    Respects your local project setup in prettierrc.
} %{
    evaluate-commands -draft -no-hooks -save-regs '|' %{
        # Select all to format
        execute-keys '%'

        # Run prettier on the selection from stdin
        set-register '|' %{
            %sh{
                echo "$kak_selection" | \
                npx prettier --stdin-filepath $kak_buffile
            }
        }

        # Replace all with content from register:
        execute-keys '|<ret>'
    }
}

define-command format-tslint -docstring %{
    Formats the current buffer using tslint.
    Writes the buffer to disk first, formats it there, and then reloads it.
} %{
    evaluate-commands -draft -no-hooks %{
        # It is not possible to format with tslint using stdin.
        # Hence, it is required that the buffer be written to disk first,
        # formatted there, and then automatically reloaded.
        set-option window autoreload 'yes'
        write
        nop %sh{
            npx tslint --fix "$kak_buffile"
        }
        hook -once window BufReload .* %{
            unset-option window autoreload
        }
    }
}

# Setting eslint as linter for JS/TS files:
hook global WinSetOption filetype=(javascript|typescript) %{
    # eslint as linter as per Kakoune Wiki.
    # Using `npm list` makes the command run on all systems regardless of the
    # location of global packages, but it is much slower.
    set window lintcmd 'run() { cat "$1" | npx eslint --format "$(npm list -g --depth=0 | head -1)/node_modules/eslint-formatter-kakoune/index.js" --stdin --stdin-filename "${kak_buffile}";} && run '
    lint-enable
}
