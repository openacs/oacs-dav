<?xml version="1.0"?>
<queryset>

  <fullquery name="oacs_dav::folder_enabled.enabled_p">
    <querytext>
      select enabled_p
      from dav_site_node_folder_map
      where folder_id=:folder_id
    </querytext>
  </fullquery>
  
  <fullquery name="oacs_dav::register_folder.add_folder">
    <querytext>
      insert into dav_site_node_folder_map
      (folder_id, node_id, enabled_p)
      values
      (:folder_id, :node_id, :enabled_p)
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::register_folder.remove_folder">
    <querytext>
      delete from dav_site_node_folder_map
      where folder_id=:folder_id
      and node_id=:node_id
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::request_folder_id.get_folder_id">
    <querytext>
      select folder_id from dav_site_node_folder_map
      where node_id=:node_id and enabled_p = 't'
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::handle_request.get_content_type">
    <querytext>
      select content_type from cr_items where item_id=:item_id
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_revision::put.set_live_revision">
    <querytext>
      update cr_items set live_revision=:revision_id
      where item_id=(select item_id from cr_revisions
                     where revision_id=:revision_id)
    </querytext>
  </fullquery>

  <fullquery
      name="oacs_dav::impl::content_folder::move.site_node_folder">
    <querytext>
      select count(*) from dav_site_node_folder_map
      where folder_id=:move_folder_id
    </querytext>
  </fullquery>

  <fullquery
      name="oacs_dav::impl::content_revision::copy.set_live_revision">
    <querytext>
      update cr_items set live_revision=latest_revision
      where item_id=:item_id
    </querytext>
  </fullquery>

</queryset>