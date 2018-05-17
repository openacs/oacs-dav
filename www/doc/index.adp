
<property name="context">{/doc/oacs-dav {webDAV Support}} {OpenACS WebDAV Support}</property>
<property name="doc(title)">OpenACS WebDAV Support</property>
<master>
<h1>OpenACS WebDAV Support</h1>
<h2>Introduction</h2>
<p>This package implements a WebDAV interface to the OpenACS
Content Repository. In addition to generic access to content items,
there is a service-contract interface so packages can define custom
handlers for WebDAV methods for objects that belong to that
package.</p>
<h2>Installation</h2>
<p>Install through the APM. If you install file-storage, WebDAV
support is installed automatically. In addition you should check
the tDAV specific configuration parameters to the AOLserver
configuration file. The default parameters work fine, they will
create webdav URLs like <em>yoursite/</em>dav/*</p>
<p>You can visit the /webdav-support/ page to control webdav access
on a per-folder basis. Packages that support WebDAV will add
folders to this list and an administrator can then activate or
deactivate the folders.</p>
<h2>How it Works</h2>
<p>OpenACS WebDAV Support requires the tDAV AOLserver module to
implement most of the WebDAV protocol. OpenACS WebDAV Support just
provides and interface between tDAV and the Content Repository</p>
<p>Each content_type that requires a custom handler much implement
the <code>dav</code> service contract. Each content type should
implement the <code>dav</code> service contract with the
implementation name the same as the content_type. This includes
operations for every WebDAV method. Some operations do not make
sense for certain object types. Specifically, content_items, which
are mapped to WebDAV resources, should not perform a MKCOL (make
collection) method. Likewise, a content_folder, or WebDAV
collection, should not allow a PUT method. In addition to the
<code>dav</code> service contract is a helper contract to allow
packages to set the initial content_type for new items created
through WebDAV. Each package should implement the
<code>dav_put_type</code> service contract with the implementation
named the same as the package key.</p>
<p>Each package instance that will allow WebDAV access should
register a package_id and folder_id for the root content_folder
that corresponds with the URI of the package&#39;s mount point
using <code>oacs_dav::register_folder</code>.</p>
<h2>Dispatching Requests</h2>
<p>A preauth filter is registered for all WebDAV methods. This
calls oacs_dav::authorize which will set oacs_dav::conn user_id to
the OpenACS user_id or 0 is the request is not authenticated. This
filter also calls oacs_dav::setup_conn sets up the basic
information needed to authorize the request. If authorization fails
a 401 HTTP response is returned requesting authentication
information. If authorization is successful the filter returns
filter_ok and the tdav::filter* filter for the method is
called.</p>
<p>The tdav::filter* commands setup global information for each
method that is independent of the storage type. After this filter
runs, the request is handled by the registered procedure for
OpenACS oacs_dav::handle_request.</p>
<p>oacs_dav::handle_request determines the package_id that should
handle the URI. This is based on the standard OpenACS site_node Tcl
API. After the package is found, the root folder for that package
is retreived from the dav_package_folder_map table. Using the
folder_id, and the URI of the request, the
<code>content_item__get_id</code> pl/sql(plpgsql) procedure is
called to find the item_id for the request. If no item_id is found
and the requested method is PUT, a new item should be created. If
the method is not PUT, a 404 error should be returned.</p>
<p>oacs_dav::handle_request will call the service contract
implementation for the content_type of the item. If the request is
a PUT, first the dav_put_type service contract for the package_key
of the request is called. For file-storage this returns
"file_storage_object" so items created by PUT are created
as file_storage_objects instead of generic content_revisions.</p>
<p>The service contract implementation for each operation must
return the response data in the format required by tDAV. The
documentation for the tdav::respond::* procedures named for each
method describe what is required.</p>
<h2>Release Notes</h2>
<p>Please file bugs in the <a href="http://openacs.org/bugtracker/openacs/">Bug Tracker</a>.</p>
