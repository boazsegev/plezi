# HTTPProtocol

JSON/XML::
support for special HTTP body types?

Charset::
parse chareset for incoming content-type in the multipart request body? (or leave if binary?)

# HTTPResponse

Set-Cookie headers

Browsers are expected to support cookies where each cookie has a size of 4KB, at least 50 cookies per domain, and at least 3000 cookies total.[20] It consists of seven components:[6][26]

(name, value) pair of the cookie (i.e. name=value)
Expiry of the cookie
Path the cookie is good for
Domain the cookie is good for
Need for a secure connection to use the cookie
Whether or not the cookie can be accessed through other means than HTTP (i.e., JavaScript)
The first component (name, value) is required to be explicitly set.

Set-Cookie: name2=value2; Expires=Wed, 09 Jun 2021 10:18:14 GMT

The value of a cookie may consist of any printable ASCII character (! through ~, unicode \u0021 through \u007E) excluding , and ; and excluding whitespace. The name of the cookie also excludes = as that is the delimiter between the name and value. The cookie standard RFC2965 is more limiting but not implemented by browsers.

The Secure and HttpOnly attributes do not have associated values. Rather, the presence of the attribute names indicates that the Secure and HttpOnly behaviors are specified.

The Secure attribute is meant to keep cookie communication limited to encrypted transmission, directing browsers to use cookies only via secure/encrypted connections. If a web server sets a cookie with a secure attribute from a non-secure connection, the cookie can still be intercepted when it is sent to the user by man-in-the-middle attacks.

The HttpOnly attribute directs browsers not to expose cookies through channels other than HTTP (and HTTPS) requests. An HttpOnly cookie is not accessible via non-HTTP methods, such as calls via JavaScript (e.g., referencing "document.cookie"), and therefore cannot be stolen easily via cross-site scripting (a pervasive attack technique).[37] Among others, Facebook and Google use the HttpOnly attribute extensively.


Set-Cookie: reg_fb_gate=deleted; Expires=Thu, 01-Jan-1970 00:00:01 GMT; Path=/; Domain=.example.com; HttpOnly

Set-Cookie: SSID=Ap4P….GTEq; Domain=foo.com; Path=/; Expires=Wed, 13 Jan 2021 22:23:01 GMT; Secure; HttpOnly


# SASS / CoffeeScript / HAML / IRB

Sass - support re-rendering in case an included file was updated (not just the source root sass file).

CoffeeScript - okay

# SSLService

fix cert and closing...

# HTTPHost

Folder Listing::
add folder listing option?

# Route
ReWrite Paths::
need to decide how to handle rewrites...

# Framework erb/Haml/Activeview
native ERB support?::
limited to 404 and 500 error codes.

ActiveView standalone support::
Should we really work on this?

