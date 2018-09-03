-module(postman_smtp).

-include_lib("postman_transport/include/types.hrl").

-behaviour(postman_transport).

%% API exports
-export([send/2, name/0, version/0]).

-define(DEFAULT_OPTIONS, [
	{enable_ssl, false}, % whether to connect on 465 in ssl mode
	{enable_tls, if_available}, % always, never, if_available
	{tls_versions, ['tlsv1', 'tlsv1.1', 'tlsv1.2']}, % used in ssl:connect, http://erlang.org/doc/man/ssl.html
	{auth, if_available},
	{hostname, smtp_util:guess_FQDN()},
	{retries, 1} % how many retries per smtp host on temporary failure
]).

-define(AUTH_PREFERENCE, [
    "CRAM-MD5",
    "LOGIN",
    "PLAIN",
    "XOAUTH2"
]).

-define(TIMEOUT, 1200000).

%%====================================================================
%% API functions
%%====================================================================
send(Email, Options) ->
	From = Email#email_rec.from,
	To = Email#email_rec.to,
	Subject = Email#email_rec.subject,
	Body = Email#email_rec.body,
	Ssl = ssl,
	Host = lists:keyfind(host, Options),
	Port = lists:keyfind(port, Options),
	Password = lists:keyfind(password, Options),
	send_mail(From, Password, To, Subject, Body, Ssl, Host, Port).

name() ->
    "Postman SMTP Transport".

version() ->
    "0.0.1".

%%====================================================================
%% Internal functions
%%====================================================================
send_mail(From, FromPassword, To, Subject, Body, Ssl, Host, Port) ->
    % Connection options
    Opts = case Ssl of
        ssl ->
            [{delay_send, false}, {verify, 0}, {nodelay, true}];
        gen_tcp ->
            [{delay_send, false}, {nodelay, true}]
    end,

    % Connect to smtp server
    case Ssl:connect(Host, Port, Opts) of
        {ok, Socket} ->
            Ssl:send(Socket, "HELO\r\n"),
            Ssl:send(Socket, "AUTH LOGIN\r\n"),
            timer:sleep(2000),
            Ssl:send(Socket, binary_to_list(base64:encode(From)) ++ "\r\n"),
            timer:sleep(2000),
            Ssl:send(Socket, binary_to_list(base64:encode(FromPassword)) ++ "\r\n"),
            timer:sleep(2000),
            Ssl:send(Socket, "MAIL FROM: <" ++ From ++ ">\r\n"),
            timer:sleep(2000),
            Ssl:send(Socket, "RCPT TO: <" ++ To ++ ">\r\n"),
            timer:sleep(2000),
            Ssl:send(Socket, "DATA\r\n"),
            timer:sleep(2000),
            Ssl:send(Socket, "From: <" ++ From ++ ">\r\n"),
            timer:sleep(2000),
            Ssl:send(Socket, "To: <" ++ To ++ ">\r\n"),
            timer:sleep(2000),
            Ssl:send(Socket, "Subject: " ++ Subject ++ "\r\n"),
            timer:sleep(2000),
            Ssl:send(Socket, "\r\n"),
            timer:sleep(2000),
            Ssl:send(Socket, Body ++ "\r\n"),
            timer:sleep(2000),
            Ssl:send(Socket, "\r\n"),
            timer:sleep(2000),
            Ssl:send(Socket, ".\r\n"),
            timer:sleep(2000),
            Ssl:send(Socket, "QUIT\r\n"),
            timer:sleep(2000),
            ssl:close(Socket),
            ok;
        {error, Error} ->
            {error, Error}
    end.
