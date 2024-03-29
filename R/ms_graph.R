#' Microsoft Graph
#'
#' Base class for interacting with Microsoft Graph API.
#'
#' @docType class
#' @section Methods:
#' - `new(tenant, app, ...)`: Initialize a new Microsoft Graph connection with the given credentials. See 'Authentication' for more details.
#' - `create_app(name, ..., add_password=TRUE, password_name=NULL, password_duration=2, certificate=NULL, create_service_principal=TRUE)`: Creates a new app registration in Azure Active Directory. See 'App creation' below.
#' - `get_app(app_id, object_id)`: Retrieves an existing app registration, via either its app ID or object ID.
#' - `list_apps(filter=NULL, n=Inf)`: Lists the app registrations in the current tenant.
#' - `delete_app(app_id, object_id, confirm=TRUE)`: Deletes an existing app registration. Any associated service principal will also be deleted.
#' - `create_service_principal(app_id, ...)`: Creates a service principal for a app registration.
#' - `get_service_principal()`: Retrieves an existing service principal.
#' - `list_service_principals(filter=NULL, n=Inf)`: Lists the service principals in the current tenant.
#' - `delete_service_principal()`: Deletes an existing service principal.
#' - `create_user(name, email, enabled=TRUE, ..., password=NULL, force_password_change=TRUE)`: Creates a new user account. By default this will be a work account (not social or local) in the current tenant, and will have a randomly generated password that must be changed at next login.
#' - `get_user(user_id, email, name)`: Retrieves an existing user account. You can supply either the user ID, email address, or display name. The default is to return the logged-in user.
#' - `list_users(filter=NULL, n=Inf)`: Lists the users in the current tenant.
#' - `delete_user(user_id, email, name, confirm=TRUE)`: Deletes a user account.
#' - `create_group(name, email, ...)`: Creates a new group. Note that only security groups can be created via the Microsoft Graph API.
#' - `get_group(group_id, name)`: Retrieves an existing group.
#' - `list_groups(filter=NULL, n=Inf)`: Lists the groups in the current tenant.
#' - `delete_group(group_id, name, confirm=TRUE)`: Deletes a group.
#' - `call_graph_endpoint(op="", ...)`: Calls the Microsoft Graph API using this object's token and tenant as authentication arguments. See [call_graph_endpoint].
#' - `call_batch_endpoint(requests=list(), ...)`: Calls the batch endpoint with a list of individual requests. See [call_batch_endpoint].
#' - `get_aad_object(id)`: Retrieves an arbitrary Azure Active Directory object by ID.
#'
#' @section Authentication:
#' The recommended way to authenticate with Microsoft Graph is via the [create_graph_login] function, which creates a new instance of this class.
#'
#' To authenticate with the `ms_graph` class directly, provide the following arguments to the `new` method:
#' - `tenant`: Your tenant ID. This can be a name ("myaadtenant"), a fully qualified domain name ("myaadtenant.onmicrosoft.com" or "mycompanyname.com"), or a GUID.
#' - `app`: The client/app ID to use to authenticate with Azure Active Directory. The default is to login interactively using the Azure CLI cross-platform app, but it's recommended to supply your own app credentials if possible.
#' - `password`: if `auth_type == "client_credentials"`, the app secret; if `auth_type == "resource_owner"`, your account password.
#' - `username`: if `auth_type == "resource_owner"`, your username.
#' - `certificate`: If `auth_type == "client_credentials", a certificate to authenticate with. This is a more secure alternative to using an app secret.
#' - `auth_type`: The OAuth authentication method to use, one of "client_credentials", "authorization_code", "device_code" or "resource_owner". See [get_azure_token] for how the default method is chosen, along with some caveats.
#' - `version`: The Azure Active Directory (AAD) version to use for authenticating.
#' - `host`: your Microsoft Graph host. Defaults to `https://graph.microsoft.com/`.
#' - `aad_host`: Azure Active Directory host for authentication. Defaults to `https://login.microsoftonline.com/`. Change this if you are using a government or private cloud.
#' - `scopes`: The Microsoft Graph scopes (permissions) to obtain for this Graph login. Only for `version=2`.
#' - `token`: Optionally, an OAuth 2.0 token, of class [AzureAuth::AzureToken]. This allows you to reuse the authentication details for an existing session. If supplied, all other arguments will be ignored.
#'
#' @section App creation:
#' The `create_app` method creates a new app registration. By default, a new app will have a randomly generated strong password with duration of 2 years. To skip assigning a password, set the `add_password` argument to FALSE.
#'
#' The `certificate` argument allows authenticating via a certificate instead of a password. This should be a character string containing the certificate public key (aka the CER file). Alternatively it can be an list, or an object of class `AzureKeyVault::stored_cert` representing a certificate stored in an Azure Key Vault. See the examples below.
#'
#' A new app will also have a service principal created for it by default. To disable this, set `create_service_principal=FALSE`.
#'
#' @section List methods:
#' All `list_*` methods have `filter` and `n` arguments to limit the number of results. The former should be an [OData expression](https://learn.microsoft.com/en-us/graph/query-parameters#filter-parameter) as a string to filter the result set on. The latter should be a number setting the maximum number of (filtered) results to return. The default values are `filter=NULL` and `n=Inf`. If `n=NULL`, the `ms_graph_pager` iterator object is returned instead to allow manual iteration over the results.
#'
#' Support in the underlying Graph API for OData queries is patchy. Not all endpoints that return lists of objects support filtering, and if they do, they may not allow all of the defined operators. If your filtering expression results in an error, you can carry out the operation without filtering and then filter the results on the client side.
#'
#' @seealso
#' [create_graph_login], [get_graph_login]
#'
#' [Microsoft Graph overview](https://learn.microsoft.com/en-us/graph/overview),
#' [REST API reference](https://learn.microsoft.com/en-us/graph/api/overview?view=graph-rest-1.0)
#'
#' @examples
#' \dontrun{
#'
#' # start a new Graph session
#' gr <- ms_graph$new(tenant="myaadtenant.onmicrosoft.com")
#'
#' # authenticate with credentials in a file
#' gr <- ms_graph$new(config_file="creds.json")
#'
#' # authenticate with device code
#' gr <- ms_graph$new(tenant="myaadtenant.onmicrosoft.com", app="app_id", auth_type="device_code")
#'
#' # retrieve an app registration
#' gr$get_app(app_id="myappid")
#'
#' # create a new app and associated service principal, set password duration to 10 years
#' app <- gr$create_app("mynewapp", password_duration=10)
#'
#' # delete the app
#' gr$delete_app(app_id=app$properties$appId)
#' # ... but better to call the object's delete method directly
#' app$delete()
#'
#' # create an app with authentication via a certificate
#' cert <- readLines("mycert.cer")
#' gr$create_app("mycertapp", password=FALSE, certificate=cert)
#'
#' # retrieving your own user details (assuming interactive authentication)
#' gr$get_user()
#'
#' # retrieving another user's details
#' gr$get_user("username@myaadtenant.onmicrosoft.com")
#' gr$get_user(email="firstname.lastname@mycompany.com")
#' gr$get_user(name="Hong Ooi")
#'
#' # get an AAD object (a group)
#' id <- gr$get_user()$list_group_memberships()[1]
#' gr$get_aad_object(id)
#'
#' # list the users in the tenant
#' gr$list_users()
#'
#' # list (guest) users with a 'gmail.com' email address
#' gr$list_users(filter="endsWith(mail,'gmail.com')")
#'
#' # list Microsoft 365 groups
#' gr$list_groups(filter="groupTypes/any(c:c eq 'Unified')")
#'
#' }
#' @format An R6 object of class `ms_graph`.
#' @export
ms_graph <- R6::R6Class("ms_graph",

public=list(
    host=NULL,
    tenant=NULL,
    token=NULL,

    # authenticate and get subscriptions
    initialize=function(tenant="common", app=.az_cli_app_id,
                        password=NULL, username=NULL, certificate=NULL, auth_type=NULL, version=2,
                        host="https://graph.microsoft.com/", aad_host="https://login.microsoftonline.com/",
                        scopes=".default", token=NULL, ...)
    {
        if(is_azure_token(token))
        {
            self$host <- httr::build_url(find_resource_host(token))
            self$tenant <- token$tenant
            self$token <- token
            return(NULL)
        }

        self$host <- host
        self$tenant <- normalize_tenant(tenant)
        app <- normalize_guid(app)

        if(version == 2)
            host <- c(paste0(host, scopes), "openid", "offline_access")

        self$token <- get_azure_token(resource=host,
            tenant=self$tenant,
            app=app,
            password=password,
            username=username,
            certificate=certificate,
            auth_type=auth_type,
            aad_host=aad_host,
            version=version,
            ...)

        NULL
    },

    create_app=function(name, ..., add_password=TRUE, password_name=NULL, password_duration=2, certificate=NULL,
        create_service_principal=TRUE)
    {
        properties <- list(displayName=name, ...)
        if(!is_empty(certificate))
        {
            key <- read_cert(certificate)
            properties <- modifyList(properties, list(
                keyCredentials=list(list(
                    key=key,
                    type="AsymmetricX509Cert",
                    usage="verify"
                ))
            ))
        }

        res <- az_app$new(
            self$token,
            self$tenant,
            self$call_graph_endpoint("applications", body=properties, encode="json", http_verb="POST")
        )

        if(create_service_principal)
            res$create_service_principal()
        if(add_password)
            res$add_password(password_name, password_duration)
        res
    },

    get_app=function(app_id=NULL, object_id=NULL)
    {
        if(!is.null(app_id))
        {
            op <- sprintf("applications?$filter=appId+eq+'%s'", app_id)
            az_app$new(self$token, self$tenant, self$call_graph_endpoint(op)$value[[1]])
        }
        else if(!is.null(object_id))
        {
            op <- file.path("applications", object_id)
            az_app$new(self$token, self$tenant, self$call_graph_endpoint(op))
        }
        else stop("Must supply either app ID or object (directory) ID")
    },

    delete_app=function(app_id=NULL, object_id=NULL, confirm=TRUE)
    {
        self$get_app(app_id, object_id)$delete(confirm=confirm)
    },

    list_apps=function(filter=NULL, n=Inf)
    {
        opts <- list(`$filter`=filter, `$count`=if(!is.null(filter)) "true")
        hdrs <- if(!is.null(filter)) httr::add_headers(consistencyLevel="eventual")
        pager <- ms_graph_pager$new(self$token, self$call_graph_endpoint("applications", options=opts, hdrs))
        extract_list_values(pager, n)
    },

    create_service_principal=function(app_id, ...)
    {
        self$get_app(app_id)$create_service_principal(...)
    },

    get_service_principal=function(app_id=NULL, object_id=NULL)
    {
        if(!is.null(app_id) && is_guid(app_id))
        {
            op <- sprintf("servicePrincipals?$filter=appId+eq+'%s'", app_id)
            az_service_principal$new(self$token, self$tenant, self$call_graph_endpoint(op)$value[[1]])
        }
        else if(!is.null(object_id) && is_guid(object_id))
        {
            op <- file.path("servicePrincipals", object_id)
            az_service_principal$new(self$token, self$tenant, self$call_graph_endpoint(op))
        }
        else stop("Must supply either app ID or object (directory) ID")
    },

    delete_service_principal=function(app_id=NULL, object_id=NULL, confirm=TRUE)
    {
        self$get_service_principal(app_id, object_id)$delete(confirm=confirm)
    },

    list_service_principals=function(filter=NULL, n=Inf)
    {
        opts <- list(`$filter`=filter, `$count`=if(!is.null(filter)) "true")
        hdrs <- if(!is.null(filter)) httr::add_headers(consistencyLevel="eventual")
        pager <- ms_graph_pager$new(self$token, self$call_graph_endpoint("servicePrincipals", options=opts, hdrs))
        extract_list_values(pager, n)
    },

    create_user=function(name, email, enabled=TRUE, ..., password=NULL, force_password_change=TRUE)
    {
        properties <- list(
            displayName=name,
            mail=email,
            userPrincipalName=email,
            mailNickname=email,
            accountEnabled=enabled
        )

        properties <- modifyList(properties, list(...))

        if(is.null(password))
            password <- openssl::base64_encode(openssl::rand_bytes(40))

        properties <- modifyList(properties, list(
            passwordProfile=list(
                password=password,
                forceChangePasswordNextSignIn=force_password_change,
                forceChangePasswordNextSignInWithMfa=FALSE
            )
        ))

        az_user$new(
            self$token,
            self$tenant,
            self$call_graph_endpoint("users", body=properties, encode="json", http_verb="POST"),
            password
        )
    },

    get_user=function(user_id=NULL, name=NULL, email=NULL)
    {
        has_id <- !is.null(user_id)
        has_name <- !is.null(name)
        has_email <- !is.null(email)
        if(has_id + has_email + has_name > 1)
            stop("Supply one of user ID, email or display name", call.=FALSE)

        if(has_email || has_name)
        {
            filter <- if(has_email) sprintf("mail eq '%s'", email) else sprintf("displayName eq '%s'", name)
            users <- self$list_users(filter=filter)
            if(length(users) != 1)
                stop("Invalid user email or name", call.=FALSE)
            return(users[[1]])
        }

        op <- if(!has_id)
            "me"
        else file.path("users", curl::curl_escape(user_id))
        az_user$new(self$token, self$tenant, self$call_graph_endpoint(op))
    },

    delete_user=function(user_id=NULL, name=NULL, email=NULL, confirm=TRUE)
    {
        self$get_user(user_id, email, name)$delete(confirm=confirm)
    },

    list_users=function(filter=NULL, n=Inf)
    {
        opts <- list(`$filter`=filter, `$count`=if(!is.null(filter)) "true")
        hdrs <- if(!is.null(filter)) httr::add_headers(consistencyLevel="eventual")
        pager <- ms_graph_pager$new(self$token, self$call_graph_endpoint("users", options=opts, hdrs))
        extract_list_values(pager, n)
    },

    create_group=function(name, email, ...)
    {
        properties <- list(
            displayName=name,
            mailEnabled=FALSE,
            mailNickname=email,
            securityEnabled=TRUE
        )

        az_group$new(
            self$token,
            self$tenant,
            self$call_graph_endpoint("groups", body=properties, encode="json", http_verb="POST")
        )
    },

    get_group=function(group_id=NULL, name=NULL)
    {
        has_id <- !is.null(group_id)
        has_name <- !is.null(name)
        if(has_id + has_name != 1)
            stop("Supply one of group ID or display name", call.=FALSE)

        if(has_name)
        {
            filter <- sprintf("displayName eq '%s'", name)
            grps <- self$list_groups(filter=filter)
            if(length(grps) != 1)
                stop("Invalid group name", call.=FALSE)
            return(grps[[1]])
        }

        op <- file.path("groups", group_id)
        az_group$new(self$token, self$tenant, self$call_graph_endpoint(op))
    },

    delete_group=function(group_id=NULL, name=NULL, confirm=TRUE)
    {
        self$get_group(group_id, name)$delete(confirm=confirm)
    },

    list_groups=function(filter=NULL, n=Inf)
    {
        opts <- list(`$filter`=filter, `$count`=if(!is.null(filter)) "true")
        hdrs <- if(!is.null(filter)) httr::add_headers(consistencyLevel="eventual")
        pager <- ms_graph_pager$new(self$token, self$call_graph_endpoint("groups", options=opts, hdrs))
        extract_list_values(pager, n)
    },

    call_graph_endpoint=function(op="", ...)
    {
        call_graph_endpoint(self$token, op, ...)
    },

    call_batch_endpoint=function(requests=list(), ...)
    {
        call_batch_endpoint(self$token, requests, ...)
    },

    get_aad_object=function(id)
    {
        res <- self$call_graph_endpoint(file.path("directoryObjects", id))
        gen <- find_class_generator(res, type_filter=NULL)
        gen$new(self$token, self$tenant, res)
    },

    print=function(...)
    {
        cat("<Microsoft Graph client>\n")
        cat("<Authentication>\n")
        fmt_token <- gsub("\n  ", "\n    ", format_auth_header(self$token))
        cat(" ", fmt_token)
        cat("---\n")
        cat(format_public_methods(self))
        invisible(self)
    }
))


assert_one_arg <- function(..., msg)
{
    arglst <- list(...)
    nulls <- sapply(arglst, is.null)
    if(sum(!nulls) != 1)
        stop(msg, call.=FALSE)
}
