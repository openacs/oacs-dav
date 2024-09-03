ad_library {

    Test procedures for oacs-dav

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2003-09-14
    @cvs-id $Id$

}

aa_register_case oacs_dav_sc_create {
    Test creation of DAV service contract
} {
    aa_true "DAV Service contract created" [db_0or1row get_dav_sc {
        select * from acs_sc_contracts where contract_name='dav'
    }]
    set sc_ops [db_list get_dav_ops {
        select operation_name from acs_sc_operations where contract_name='dav'
    }]
    set valid_ops [list get put mkcol copy propfind proppatch move delete]
    foreach op_name $valid_ops {
        aa_true "$op_name operation created" \
            {$op_name in $sc_ops}
    }

    aa_true "DAV put_type Service contract created" \
        [db_0or1row get_dav_pt_sc {
            select * from acs_sc_contracts where contract_name='dav_put_type'
        }]
    aa_true "get_type operation created" \
        [db_0or1row get_dav_pt_op {
            select operation_name from acs_sc_operations where
            contract_name='dav_put_type'
            and operation_name='get_type'

        }]
}

aa_register_case -procs {
    oacs_dav::conn
    oacs_dav::register_folder
    oacs_dav::impl::content_revision::put
    acs_root_dir
    site_node::get
    content::revision::get_cr_file_path
    cr_import_content
} oacs_dav_put {
    Test generic cr_revision PUT
} {
    aa_run_with_teardown -rollback -test_code {
        array set sn [site_node::get -url "/"]
        set package_id $sn(package_id)
        set name "__test_file.html"
        oacs_dav::conn -set item_name $name
        set uri "/${name}"
        set item_id ""
        oacs_dav::conn -set method "PUT"
        oacs_dav::conn -set item_id $item_id
        oacs_dav::conn -set uri $uri
        oacs_dav::conn -set urlv $name
        oacs_dav::conn -set tmpfile \
            "[acs_root_dir]/packages/oacs-dav/tcl/test/$name"
        # we probably want to create a bunch of files in the filesystem
        # and test mime type and other attributes to make sure the
        # content gets in the database
        set tmpfile [oacs_dav::conn tmpfile]
        set tmpfilesize [file size $tmpfile]
        set fd [open $tmpfile r]
        set orig_content [read $fd]
        close $fd
        set folder_id [db_exec_plsql create_test_folder ""]
        aa_log "Folder Created $folder_id package_id $package_id"
        oacs_dav::conn -set folder_id $folder_id
        db_exec_plsql register_content_type ""
        oacs_dav::register_folder $folder_id $sn(node_id)
        set response [oacs_dav::impl::content_revision::put]
        ## Rewrite the file, as put operation would destroy it
        set fd [open $tmpfile w]
        puts -nonewline $fd $orig_content
        close $fd
        ##
        aa_log "Response was $response"
        set new_item_id [db_string item_exists "" -default ""]
        aa_log "Item_id=$new_item_id"
        aa_true "Content Item Created" {$new_item_id ne ""}
        set revision_id [db_string revision_exists "" -default ""]
        aa_true "Content Revision Created"  {$revision_id ne ""}
        set cr_filename [content::revision::get_cr_file_path -revision_id $revision_id]
        aa_true "Content Attribute Set" \
            {$tmpfilesize == [file size $cr_filename]}
    }
}

aa_register_case -procs {
    oacs_dav::conn
    oacs_dav::register_folder
    oacs_dav::impl::content_folder::mkcol
    site_node::get
} oacs_dav_mkcol {
    Test generic content folder creation
} {
    aa_run_with_teardown -rollback -test_code {
        array set sn [site_node::get -url "/"]
        set package_id $sn(package_id)
        set name "__test_folder1/__test_folder2"
        set uri "/"
        oacs_dav::conn -set item_id ""
        oacs_dav::conn -set uri $uri
        oacs_dav::conn -set extra_url $name
        oacs_dav::conn -set urlv [split $uri "/"]
        oacs_dav::conn -set package_id $package_id
        set parent_folder_id [db_string get_parent_folder "" -default "-100"]
        oacs_dav::conn -set folder_id $parent_folder_id
        oacs_dav::register_folder $parent_folder_id $sn(node_id)
        foreach fname [split $name "/"] {
            set uri "$uri${fname}/"
            oacs_dav::conn -set item_name $fname
            oacs_dav::conn -set uri $uri
            oacs_dav::conn -set extra_url $fname
            oacs_dav::conn -set urlv [split $uri "/"]
            aa_log "name $fname uri $uri"
            set response [oacs_dav::impl::content_folder::mkcol]
            set new_folder_id [db_string folder_exists "" -default ""]
            aa_true "Content Folder $fname created" {$new_folder_id ne ""}
        }
    }
}

aa_register_case -procs {
    oacs_dav::children_have_permission_p
} oacs_dav_children_have_permission_p {
    Test the api that checks whether one has permissions on all
    children.
} {
    aa_run_with_teardown -rollback -test_code {
        set user [acs::test::user::create]
        set user_id [dict get $user user_id]

        set admin [acs::test::user::create -admin]
        set admin_id [dict get $admin user_id]

        aa_section {Create a folder containing a cr_item with a few revisions}

        set root_folder_id [db_string get_root_folder {
            select min(item_id) from cr_items
            where content_type = 'content_folder'
            and parent_id <= 0
        }]

        set name __OACS_DAV_TEST_FOLDER
        set folder_id [content::folder::new \
                                 -label $name \
                                 -name $name]

        content::folder::register_content_type \
            -folder_id $folder_id \
            -content_type "content_revision"

        set item_id [content::item::new \
                               -name "test_item_one" \
                               -parent_id $folder_id \
                               -storage_type "text"]

        set title "Test Title"
        set revision_id [content::revision::new \
                             -item_id $item_id \
                             -title $title \
                             -description "Test Description" \
                             -content "Test Content"]

        set title "Test Title2"
        set revision_id [content::revision::new \
                             -item_id $item_id \
                             -title $title \
                             -description "Test Description2" \
                             -content "Test Content2"]

        foreach priv {read write delete admin} {
            aa_false "User does not have permission to '$priv' on the folder" \
                [oacs_dav::children_have_permission_p \
                     -user_id $user_id -item_id $folder_id -privilege $priv]
            aa_true "Admin has permission to '$priv' on the folder" \
                [oacs_dav::children_have_permission_p \
                     -user_id $admin_id -item_id $folder_id -privilege $priv]
        }

        aa_section "Set cr_item to not inherit permissions from the folder"
        db_dml query {update acs_objects set security_inherit_p = 'f' where object_id = :item_id}

        aa_log "Grant read permission on the folder"
        permission::grant -party_id $user_id -object_id $folder_id -privilege read

        aa_false "User does still not have permission to 'read' on the folder (no permissions on item)" \
            [oacs_dav::children_have_permission_p \
                 -user_id $user_id -item_id $folder_id -privilege read]

        aa_log "Grant read permission on the item"
        permission::grant -party_id $user_id -object_id $item_id -privilege read

        aa_false "User still does not have permission 'read' on the item (no delete permission on the revisions)" \
            [oacs_dav::children_have_permission_p \
                 -user_id $user_id -item_id $item_id -privilege read]

        aa_log "Grant delete permission on the item"
        permission::grant -party_id $user_id -object_id $item_id -privilege delete
        aa_true "User has now permission 'read' on the item (revision inherit from item)" \
            [oacs_dav::children_have_permission_p \
                 -user_id $user_id -item_id $item_id -privilege read]

        aa_log "Grant delete permission singularly to the revisions"
        foreach revision_id [db_list q {select revision_id from cr_revisions where item_id = :item_id}] {
            permission::grant -party_id $user_id -object_id $revision_id -privilege delete
        }

        aa_true "User now havs permission 'read' on the item" \
            [oacs_dav::children_have_permission_p \
                 -user_id $user_id -item_id $item_id -privilege read]

        aa_section "Set cr_item to inherit permissions from the folder"
        db_dml query {update acs_objects set security_inherit_p = 't' where object_id = :item_id}

        aa_true "User now has permission 'read' on the folder" \
            [oacs_dav::children_have_permission_p \
                 -user_id $user_id -item_id $folder_id -privilege read]

        aa_log "Revoke read permission on the item"
        permission::revoke -party_id $user_id -object_id $item_id -privilege read

        aa_true "User still has permission 'read' on the folder" \
            [oacs_dav::children_have_permission_p \
                 -user_id $user_id -item_id $folder_id -privilege read]
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
