cp node_modules/bootstrap-icons/font/fonts/* public/styles/fonts &&
cp node_modules/firebird-common/src/public/fonts/mulish* public/fonts &&
cp node_modules/firebird-common/src/public/elephant.svg public/images &&
sass $* assets/styles:public/styles --style=compressed --load-path=node_modules
