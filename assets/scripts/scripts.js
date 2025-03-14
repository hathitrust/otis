import 'bootstrap/dist/css/bootstrap.min.css'
import 'bootstrap-table/dist/bootstrap-table.min.css'
import 'bootstrap-table/dist/extensions/filter-control/bootstrap-table-filter-control.css'
import 'select2/dist/css/select2.css'
import 'ckeditor5/ckeditor5.css'

import './jquery';

import 'bootstrap';
import 'bootstrap-table';

import select2 from 'select2';
import 'select2/dist/css/select2.css';
select2(window, $);

//import BootstrapTable from 'bootstrap-table/dist/bootstrap-table.js';

//import 'bootstrap-table/dist/bootstrap-table.js';
//import 'bootstrap-table/dist/bootstrap-table.css';

// Bootstrap-table locales
import 'bootstrap-table/dist/locale/bootstrap-table-en-US.min.js'
import 'bootstrap-table/dist/locale/bootstrap-table-ja-JP.min.js'

// select2 locales
$.fn.select2.amd.define('select2/i18n/en',[],require("select2/dist/js/i18n/en"))
$.fn.select2.amd.define('select2/i18n/ja',[],require("select2/dist/js/i18n/ja"))
//import 'select2/dist/js/i18n/en.js'
//import 'select2/dist/js/i18n/ja.js'

import Export from 'bootstrap-table/dist/extensions/export/bootstrap-table-export.js'
import FilterControl from 'bootstrap-table/dist/extensions/filter-control/bootstrap-table-filter-control.min.js'

import 'tableexport.jquery.plugin'
