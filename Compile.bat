copy /v /y ".\scripting\1.10\FFCR\" ".\scripting\1.8\FFCR\"
copy /v /y ".\scripting\1.10\forlix_floodcheck_redux.sp" ".\scripting\1.8\forlix_floodcheck_redux.sp"

cd ./scripting/1.8
spcomp.exe forlix_floodcheck_redux.sp -o../../plugins/forlix_floodcheck_redux_legacy.smx

cd ../1.10
spcomp.exe forlix_floodcheck_redux.sp -o../../plugins/forlix_floodcheck_redux.smx
pause