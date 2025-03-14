npx esbuild "assets/scripts/**/scripts.js" --entry-names=[dir]/[name] --outbase=assets/scripts --bundle --minify --outdir=public/scripts $*
npx esbuild "assets/scripts/**/ckeditor.js" --entry-names=[dir]/[name] --outbase=assets/scripts --bundle --minify --outdir=public/scripts $*
