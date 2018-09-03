-type smtp_opts() :: list(smtp_opt()).
-type tls_vsn() :: 'tlsv1'
                | 'tlsv1.1'
                | 'tlsv1.2'.

-type smtp_opt() :: {host, Host :: string()}
                 | {port, Port :: non_neg_integer()}
                 | {enable_ssl, Ssl :: boolean()}
                 | {enable_tls, always | never | if_available}
                 | {tls_versions, list(tls_vsn())}
                 | {enable_dkim, Dkim :: boolean()}
                 | {dkim_key, Key :: binary()}
                 | {retries, Retries :: non_neg_integer()}
                 | {auth, always | never | if_available}
                 | {username, User :: string()}
                 | {password, Password :: string()}.
