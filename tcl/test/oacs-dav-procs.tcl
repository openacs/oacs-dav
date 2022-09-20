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

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
