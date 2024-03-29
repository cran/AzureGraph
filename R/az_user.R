#' User in Azure Active Directory
#'
#' Class representing an AAD user account.
#'
#' @docType class
#' @section Fields:
#' - `token`: The token used to authenticate with the Graph host.
#' - `tenant`: The Azure Active Directory tenant for this user.
#' - `type`: always "user" for a user object.
#' - `properties`: The user properties.
#' @section Methods:
#' - `new(...)`: Initialize a new user object. Do not call this directly; see 'Initialization' below.
#' - `delete(confirm=TRUE)`: Delete a user account. By default, ask for confirmation first.
#' - `update(...)`: Update the user information in Azure Active Directory.
#' - `do_operation(...)`: Carry out an arbitrary operation on the user account.
#' - `sync_fields()`: Synchronise the R object with the app data in Azure Active Directory.
#' - `list_direct_memberships(filter=NULL, n=Inf)`: List the groups and directory roles this user is a direct member of.
#' - `list_owned_objects(type=c("user", "group", "application", "servicePrincipal"), filter=NULL, n=Inf)`: List directory objects (groups/apps/service principals) owned by this user. Specify the `type` argument to limit the result to specific object type(s).
#' - `list_created_objects(type=c("user", "group", "application", "servicePrincipal"), filter=NULL, n=Inf)`: List directory objects (groups/apps/service principals) created by this user. Specify the `type` argument to limit the result to specific object type(s).
#' - `list_owned_devices(filter=NULL, n=Inf)`: List the devices owned by this user.
#' - `list_registered_devices(filter=NULL, n=Inf)`: List the devices registered by this user.
#' - `reset_password(password=NULL, force_password_change=TRUE)`: Resets a user password. By default the new password will be randomly generated, and must be changed at next login.
#'
#' @section Initialization:
#' Creating new objects of this class should be done via the `create_user` and `get_user` methods of the [ms_graph] and [az_app] classes. Calling the `new()` method for this class only constructs the R object; it does not call the Microsoft Graph API to create the actual user account.
#'
#' @section List methods:
#' All `list_*` methods have `filter` and `n` arguments to limit the number of results. The former should be an [OData expression](https://learn.microsoft.com/en-us/graph/query-parameters#filter-parameter) as a string to filter the result set on. The latter should be a number setting the maximum number of (filtered) results to return. The default values are `filter=NULL` and `n=Inf`. If `n=NULL`, the `ms_graph_pager` iterator object is returned instead to allow manual iteration over the results.
#'
#' Support in the underlying Graph API for OData queries is patchy. Not all endpoints that return lists of objects support filtering, and if they do, they may not allow all of the defined operators. If your filtering expression results in an error, you can carry out the operation without filtering and then filter the results on the client side.
#' @seealso
#' [ms_graph], [az_app], [az_group], [az_device], [az_object]
#'
#' [Microsoft Graph overview](https://learn.microsoft.com/en-us/graph/overview),
#' [REST API reference](https://learn.microsoft.com/en-us/graph/api/overview?view=graph-rest-1.0)
#'
#' @examples
#' \dontrun{
#'
#' gr <- get_graph_login()
#'
#' # my user account
#' gr$get_user()
#'
#' # another user account
#' usr <- gr$get_user("myname@aadtenant.com")
#'
#' grps <- usr$list_direct_memberships()
#' head(grps)
#'
#' # owned objects
#' usr$list_owned_objects()
#'
#' # owned apps and service principals
#' usr$list_owned_objects(type=c("application", "servicePrincipal"))
#'
#' # first 5 objects
#' usr$list_owned_objects(n=5)
#'
#' # get the pager object
#' pager <- usr$list_owned_objects(n=NULL)
#' pager$value
#'
#' }
#' @format An R6 object of class `az_user`, inheriting from `az_object`.
#' @export
az_user <- R6::R6Class("az_user", inherit=az_object,

public=list(

    password=NULL,

    initialize=function(token, tenant=NULL, properties=NULL, password=NULL)
    {
        self$type <- "user"
        private$api_type <- "users"
        self$password <- password
        super$initialize(token, tenant, properties)
    },

    reset_password=function(password=NULL, force_password_change=TRUE)
    {
        if(is.null(password))
            password <- openssl::base64_encode(openssl::rand_bytes(40))

        properties <- modifyList(properties, list(
            passwordProfile=list(
                password=password,
                forceChangePasswordNextSignIn=force_password_change,
                forceChangePasswordNextSignInWithMfa=FALSE
            )
        ))

        self$do_operation(body=properties, encode="json", http_verb="PATCH")
        self$properties <- self$do_operation()
        self$password <- password
        password
    },

    list_owned_objects=function(type=c("user", "group", "application", "servicePrincipal"), filter=NULL, n=Inf)
    {
        opts <- list(`$filter`=filter, `$count`=if(!is.null(filter)) "true")
        hdrs <- if(!is.null(filter)) httr::add_headers(consistencyLevel="eventual")
        pager <- self$get_list_pager(self$do_operation("ownedObjects", options=opts, hdrs), type_filter=type)
        extract_list_values(pager, n)
    },

    list_created_objects=function(type=c("user", "group", "application", "servicePrincipal"), filter=NULL, n=Inf)
    {
        opts <- list(`$filter`=filter, `$count`=if(!is.null(filter)) "true")
        hdrs <- if(!is.null(filter)) httr::add_headers(consistencyLevel="eventual")
        pager <- self$get_list_pager(self$do_operation("createdObjects", options=opts, hdrs), type_filter=type)
        extract_list_values(pager, n)
    },

    list_owned_devices=function(filter=NULL, n=Inf)
    {
        opts <- list(`$filter`=filter, `$count`=if(!is.null(filter)) "true")
        hdrs <- if(!is.null(filter)) httr::add_headers(consistencyLevel="eventual")
        pager <- self$get_list_pager(self$do_operation("ownedDevices", options=opts, hdrs))
        extract_list_values(pager, n)
    },

    list_direct_memberships=function(filter=NULL, n=Inf)
    {
        opts <- list(`$filter`=filter, `$count`=if(!is.null(filter)) "true")
        hdrs <- if(!is.null(filter)) httr::add_headers(consistencyLevel="eventual")
        pager <- self$get_list_pager(self$do_operation("memberOf", options=opts, hdrs))
        extract_list_values(pager, n)
    },

    print=function(...)
    {
        cat("<Graph user account '", self$properties$displayName, "'>\n", sep="")
        cat("  principal name:", self$properties$userPrincipalName, "\n")
        cat("  email:", self$properties$mail, "\n")
        cat("  directory id:", self$properties$id, "\n")
        cat("---\n")
        cat(format_public_methods(self))
        invisible(self)
    }
))
