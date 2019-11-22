copy /v /y ".\scripting\1.10\FFC\" ".\scripting\1.8\FFC\"
copy /v /y ".\scripting\1.10\forlix_floodcheck.sp" ".\scripting\1.8\forlix_floodcheck.sp"

cd ./scripting/1.8
spcomp.exe forlix_floodcheck.sp -o../../plugins/forlix_floodcheck_legacy.smx

cd ../1.10
spcomp.exe forlix_floodcheck.sp -o../../plugins/forlix_floodcheck.smx
pause