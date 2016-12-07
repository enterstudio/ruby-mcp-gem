This is an example CLI for communicating with the Cimpress Platform APIs (developer.cimpress.io). 

Before starting, you'll need to install the Ruby 2.2.x installation version from railsinstaller.org. 

Once that's complete, go ahead and get yourself an account on the platform portal. 

Note that your 'username' for this CLI is going to be your developer account name. Currently, that means you'll be 
supplying your cimpress email address as the 'user'.  

When you start,  you will need to supply two parameters to the client: your username (i.e. cimpress email address) and a 'mode', in this 
example, list_products. 

> ruby ./mcp.rb -u bclark@cimpress.com -m list_products

Alternatively, you can just provide a refresh token with -t: 

> ruby ./mcp.rb -t <token> -m list_products


Adding support for new APIs: 

You will need the client ID for the API in question- find it by visiting https://developer.cimpress.io/docs/siboz0XUowgP2K5GkgViQ8aVf8zlOnwF/apis/auth0.html and reading the section on client IDs. 
