for file in "${0%/*}"/*.apk; do  
  echo "安装apk文件 $file"  
  pm install -r -t -d -g "$file"  
done  