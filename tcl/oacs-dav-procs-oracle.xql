<?xml version="1.0"?>
<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>
  <fullquery name="oacs_dav::conn_setup.get_item_id">
    <querytext>
      select content_item.get_id(
              name => :item_name,
              root_folder_id => :parent_id,
              resolve_index_p => 'f')
    </querytext>
  </fullquery>

  <fullquery
    name="oacs_dav::impl::content_folder::propfind.get_properties">
    <querytext>
      select nvl (cr.content_length,4096) as content_length,
	nvl (cr.mime_type,'*/*') as mime_type,
	to_char(timezone('GMT',o.creation_date) :: timestamptz ,'YYYY-MM-DD"T"HH:MM:SS.MS"Z"') as creation_date,
	to_char(timezone('GMT',o.last_modified) :: timestamptz ,'Dy, DD Mon YYYY HH:MM:SS TZ') as last_modified,
	ci1.item_id,
	case when ci1.item_id=ci2.item_id then '' else ci1.name end as name,
	content_item.get_path(ci1.item_id,:folder_id) as item_uri,
	case when o.object_type='content_folder' then 1 else 0 end
	as collection_p
      from (
		select * from cr_items
		connect by prior item_id=parent_id
		start with item_id=:item_id  
	) ci1,
      cr_revisions, 
      acs_objects o
     where 
      ci1.live_revision(+) = cr.revision_id,
     and exists (select 1
                  from acs_object_party_privilege_map m
                  where m.object_id = ci1.item_id
                  and m.party_id = :user_id
                  and m.privilege = 'read')
    </querytext>
  </fullquery>

  <fullquery
    name="oacs_dav::impl::content_revision::propfind.get_properties">
    <querytext>
      select
	ci.item_id,
	ci.name,
	content_item__get_path(ci.item_id,:folder_id) as item_uri,
	coalesce(cr.mime_type,'*/*') as mime_type,
	cr.content_length,
	to_char(timezone('GMT',o.creation_date) :: timestamptz ,'YYYY-MM-DD"T"HH:MM:SS.MS"Z"') as creation_date,
	to_char(timezone('GMT',o.last_modified) :: timestamptz ,'Dy, DD Mon YYYY HH:MM:SS TZ') as last_modified
      from cr_items ci,
      acs_objects o,
      cr_revisions cr
      where 
      ci.item_id=:item_id
      and ci.item_id = o.object_id
      and cr.revision_id=ci.live_revision
    </querytext>
  </fullquery>

  <fullquery
    name="oacs_dav::impl::content_folder::mkcol.create_folder">
    <querytext>
      select content_folder.new(
              name => :new_folder_name,
              label => :label,
              description => :description,
              parent_id => :parent_id,
              context_id => :parent_id,
              new_folder_id => NULL,
              creation_date => current_timestamp,
              creation_user => :user_id,
              creation_ip => :peer_addr
      )
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_folder::copy.copy_folder">
    <querytext>
      select content_folder.copy (
              folder_id => :copy_folder_id,
              target_folder_id => :new_parent_folder_id,
              creation_user => :user_id,
              creation_ip => :peer_addr,
              name => :new_name
      )
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_folder::move.move_folder">
    <querytext>
      select content_folder.move (
              folder_id => :move_folder_id,
              target_folder_id => :new_parent_folder_id,
              name => :new_name
      )
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_folder::move.rename_folder">
    <querytext>
      select content_folder.rename (
              folder_id => :move_folder_id,
              name => :new_name,
              label => NULL,
              description => NULL
      )
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_revision::move.move_item">
    <querytext>
      select content_item.move (
              item_id => :item_id,
              target_folder_id => :new_parent_folder_id,
              name => :new_name
      )
    </querytext>
  </fullquery>

  <fullquery
      name="oacs_dav::impl::content_revision::move.rename_item">
    <querytext>
      select content_item.rename (
              item_id => :item_id,
              name => :new_name
      )
    </querytext>
  </fullquery>
  
  <fullquery name="oacs_dav::impl::content_revision::copy.copy_item">
    <querytext>
      select content_item.copy (
              item_id => :copy_item_id,
              target_id => :new_parent_folder_id,
              creation_user => :user_id,
              creation_ip => :peer_addr,
              name => :new_name
      )
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_revision::copy.delete_for_move">
    <querytext>
      select content_item.delete(
              item_id => :dest_item_id
      )
    </querytext>
  </fullquery>
  
  <fullquery name="oacs_dav::impl::content_revision::move.delete_for_copy">
    <querytext>
      select content_item.delete(
              item_id => :dest_item_id
      )
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_revision::delete.delete_item">
    <querytext>
      select content_item.delete (
              item_id => :item_id
      )
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_folder::delete.delete_folder">
    <querytext>
      select content_folder.delete (
              folder_id => :item_id,
              cascade_p => 't'
      )
    </querytext>
  </fullquery>


  <fullquery name="oacs_dav::item_parent_folder_id.get_parent_folder_id">
    <querytext>
      select content_item.get_id(
              name=> :parent_name,
              root_folder_id => :root_folder_id,
              resolve_index_p => 'f')
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_folder::copy.get_dest_id">
    <querytext>
	select content_item.get_id(
             name => :new_name,
             root_folder_id => :new_parent_folder_id,
             resolve_index_p => 'f')
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_folder::move.get_dest_id">
    <querytext>
	select content_item.get_id(
             name => :new_name,
             root_folder_id => :new_parent_folder_id,
             resolve_index_p => 'f')
    </querytext>
  </fullquery>

  <fullquery
    name="oacs_dav::impl::content_folder::move.delete_for_move">
    <querytext>
      select content_folder.delete(
              folder_id => :dest_item_id,
              cascade_p => 't');
    </querytext>
  </fullquery>

  <fullquery
    name="oacs_dav::impl::content_folder::copy.delete_for_copy">
    <querytext>
      select content_folder.delete(
              folder_id => :dest_item_id,
              cascade_p => 't');
    </querytext>
  </fullquery>
  
  <fullquery name="oacs_dav::impl::content_revision::copy.get_dest_id">
    <querytext>
	select content_item.get_id(
             name => :new_name,
             root_folder_id => :new_parent_folder_id,
             resolve_index_p => 'f')
    </querytext>
  </fullquery>

  <fullquery name="oacs_dav::impl::content_revision::move.get_dest_id">
    <querytext>
	select content_item.get_id(
             name => :new_name,
             root_folder_id => :new_parent_folder_id,
             resolve_index_p => 'f')
    </querytext>
  </fullquery>

</queryset>