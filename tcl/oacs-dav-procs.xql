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
      (node_id, folder_id, enabled_p)
      values
      (:node_id, :folder_id, :enabled_p)
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::unregister_folder.remove_folder">
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

  <fullquery name="oacs_dav::impl::content_folder::move.update_label">
    <querytext>
      update cr_folders 
	set label = :new_name
        where folder_id=:move_folder_id
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_folder::copy.get_new_folder_id">
    <querytext>
      select item_id 
      from cr_items
      where name = :new_name
      and parent_id = :new_parent_folder_id
    </querytext>
  </fullquery>

  <fullquery
      name="oacs_dav::impl::content_revision::copy.set_live_revision">
    <querytext>
      update cr_items set live_revision=latest_revision
      where item_id=:item_id
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_revision::move.update_title">
    <querytext>
      update cr_revisions 
	set title = :new_name
        where revision_id = (select latest_revision from cr_items
				where item_id=:item_id)
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_folder::copy.update_child_revisions">
      <querytext>
	update cr_items 
	set live_revision=latest_revision
	where exists (
		select 1 
		from
		(select ci1.item_id as child_item_id 
                from cr_items ci1, cr_items ci2
		where ci2.item_id=:new_folder_id
	        and ci1.tree_sortkey 
	        between ci2.tree_sortkey and tree_right(ci2.tree_sortkey)
                ) children 
                where item_id=child_item_id 
                      )
      </querytext>
  </fullquery>

</queryset>
