#' Azure Active Directory object
#'
#' Base class representing an Azure Active Directory object in Microsoft Graph.
#'
#' @docType class
#' @section Fields:
#' - `token`: The token used to authenticate with the Graph host.
#' - `tenant`: The Azure Active Directory tenant for this object.
#' - `type`: The type of object: user, group, application or service principal.
#' - `properties`: The object properties.
#' @section Methods:
#' - `new(...)`: Initialize a new directory object. Do not call this directly; see 'Initialization' below.
#' - `delete(confirm=TRUE)`: Delete an object. By default, ask for confirmation first.
#' - `update(...)`: Update the object information in Azure Active Directory.
#' - `do_operation(...)`: Carry out an arbitrary operation on the object.
#' - `sync_fields()`: Synchronise the R object with the data in Azure Active Directory.
#' - `list_group_memberships(security_only=FALSE, filter=NULL, n=Inf)`: Return the IDs of all groups this object is a member of. If `security_only` is TRUE, only security group IDs are returned.
#' - `list_object_memberships(security_only=FALSE, filter=NULL, n=Inf)`: Return the IDs of all groups, administrative units and directory roles this object is a member of.
#'
#' @section Initialization:
#' Objects of this class should not be created directly. Instead, create an object of the appropriate subclass: [az_app], [az_service_principal], [az_user], [az_group].
#'
#' @section List methods:
#' All `list_*` methods have `filter` and `n` arguments to limit the number of results. The former should be an [OData expression](https://learn.microsoft.com/en-us/graph/query-parameters#filter-parameter) as a string to filter the result set on. The latter should be a number setting the maximum number of (filtered) results to return. The default values are `filter=NULL` and `n=Inf`. If `n=NULL`, the `ms_graph_pager` iterator object is returned instead to allow manual iteration over the results.
#'
#' Support in the underlying Graph API for OData queries is patchy. Not all endpoints that return lists of objects support filtering, and if they do, they may not allow all of the defined operators. If your filtering expression results in an error, you can carry out the operation without filtering and then filter the results on the client side.
#' @seealso
#' [ms_graph], [az_app], [az_service_principal], [az_user], [az_group]
#'
#' [Microsoft Graph overview](https://learn.microsoft.com/en-us/graph/overview),
#' [REST API reference](https://learn.microsoft.com/en-us/graph/api/overview?view=graph-rest-1.0)
#'
#' @format An R6 object of class `az_object`, inheriting from `ms_object`.
#' @export
az_object <- R6::R6Class("az_object", inherit=ms_object,

public=list(

    list_object_memberships=function(security_only=FALSE, filter=NULL, n=Inf)
    {
        if(!is.null(filter))
            stop("This method doesn't support filtering", call.=FALSE)
        body <- list(securityEnabledOnly=security_only)
        pager <- self$get_list_pager(self$do_operation("getMemberObjects", body=body, http_verb="POST"),
            generate_objects=FALSE)
        unlist(extract_list_values(pager, n))
    },

    list_group_memberships=function(security_only=FALSE, filter=NULL, n=Inf)
    {
        if(!is.null(filter))
            stop("This method doesn't support filtering", call.=FALSE)
        body <- list(securityEnabledOnly=security_only)
        pager <- self$get_list_pager(self$do_operation("getMemberGroups", body=body,  http_verb="POST"),
            generate_objects=FALSE)
        unlist(extract_list_values(pager, n))
    },

    print=function(...)
    {
        cat("<Azure Active Directory object '", self$properties$displayName, "'>\n", sep="")
        cat("  directory id:", self$properties$id, "\n")
        cat("---\n")
        cat(format_public_methods(self))
        invisible(self)
    }
))

