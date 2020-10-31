# ╭────────────────╥────────────╮
# │ Author:        ║ File:      │
# │ Martin Schenck ║ jsts.kak   │
# ╞════════════════╩════════════╡
# │ JS/TS extension             │
# ╞═════════════════════════════╡
# │ github.com/schemar/kak-jsts │
# ╰─────────────────────────────╯

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook global WinSetOption filetype=(javascript|typescript) %{
    # eslint as linter as per Kakoune Wiki.
    # Using `npm list` makes the command run on all systems regardless of the
    # location of global packages, but it is much slower.
    set window lintcmd 'run() { cat "$1" | npx eslint --format "$(npm list -g --depth=0 | head -1)/node_modules/eslint-formatter-kakoune/index.js" --stdin --stdin-filename "${kak_buffile}";} && run '
    lint-show-diagnostics

    alias window alt jsts-alternative-file

    hook -once -always window WinSetOption filetype=.* %{
        unalias window alt jsts-alternative-file
    }
}

# Commands
# ‾‾‾‾‾‾‾‾

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
            format_out="$(mktemp)"
            cat | \
            npx eslint --format json \
                       --fix-dry-run \
                       --stdin \
                       --stdin-filename "$kak_buffile" | \
            jq -j ".[].output" > "$format_out"
            if [ $? -eq 0 ] && [ $(wc -c < "$format_out") -gt 4 ]; then
                cat "$format_out"
            else
                printf 'eval -client %s %%{ fail eslint formatter returned an error %s }\n' "$kak_client" "$?" | kak -p "$kak_session"
                printf "%s" "$kak_quoted_selection"
            fi
            rm -f "$format_out"
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

define-command jsts-alternative-file -docstring %{
    Jump to the alternate file (implementation ↔ test).
    Jumps between implementation und .test.(js|ts) or .spec.(js|ts) in the same directory.
} %{
    evaluate-commands %sh{
        case $kak_buffile in
            *.test.ts)
                altfile=${kak_buffile%.test.ts}.ts
                test ! -f "$altfile" && echo "fail 'implementation file not found'" && exit
            ;;
            *.test.js)
                altfile=${kak_buffile%.test.js}.js
                test ! -f "$altfile" && echo "fail 'implementation file not found'" && exit
            ;;
            *.spec.ts)
                altfile=${kak_buffile%.spec.ts}.ts
                test ! -f "$altfile" && echo "fail 'implementation file not found'" && exit
            ;;
            *.spec.js)
                altfile=${kak_buffile%.spec.js}.js
                test ! -f "$altfile" && echo "fail 'implementation file not found'" && exit
            ;;
            *.ts)
                altfile=${kak_buffile%.ts}.test.ts
                test ! -f "$altfile" && \
                    # Check for spec if test doesn't exist:
                    altfile=${kak_buffile%.ts}.spec.ts && \
                    test ! -f "$altfile" && \
                    echo "fail 'test file not found'" && \
                    exit
            ;;
            *.js)
                altfile=${kak_buffile%.js}.test.js
                test ! -f "$altfile" && \
                    # Check for spec if test doesn't exist:
                    altfile=${kak_buffile%.js}.spec.js && \
                    test ! -f "$altfile" && \
                    echo "fail 'test file not found'" && \
                    exit
            ;;
            *)
                echo "fail 'alternative file not found'" && exit
            ;;
        esac
        printf "edit '%s'" "${altfile}"
    }
}
