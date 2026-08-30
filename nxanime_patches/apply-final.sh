#!/usr/bin/env bash
set -euo pipefail
MAIN="nxanime_source/main.cpp"
TMP="${MAIN}.tmp"
awk '
BEGIN { skip=0; skip_proxy_ui=0 }
skip { if ($0 ~ /^}$/) skip=0; next }
skip_proxy_ui { if ($0 ~ /^        }$/) skip_proxy_ui=0; next }
/^static void launcher_force_builtin_direct\(State& st\)\{/ {
  print "static void launcher_force_builtin_direct(State& st){ (void)st; }"
  skip=1; next
}
/^static void launcher_cycle_proxy\(State& st,int dir\)\{/ {
  print "static void launcher_cycle_proxy(State& st,int dir){"
  print "    st.proxy.mode=(ProxyMode)wrapi((int)st.proxy.mode+dir,3);"
  print "    proxy_config_save(&st.proxy);"
  print "    st.status=std::string(\"代理模式：\")+proxy_mode_cn(st.proxy.mode);"
  print "}"
  skip=1; next
}
/^static void launcher_edit\(State& st\)\{/ {
  print "static void launcher_edit(State& st){"
  print "    if(st.launcher_row==0){"
  print "        if(!launcher_custom_source()){"
  print "            st.status=\"X 编辑仅用于自定义播放源\";"
  print "            return;"
  print "        }"
  print "        std::string value=provider_custom_source();"
  print "        if(value.empty())value=\"https://\";"
  print "        if(!keyboard(\"添加播放源\",\"输入兼容 MacCMS API 的根地址\",value,value)){st.status=\"已取消编辑播放源\";return;}"
  print "        std::string msg;if(provider_source_set_custom(value,msg)){st.connected=false;}st.status=msg;return;"
  print "    }"
  print "    st.status=\"直连 / HTTP / SOCKS5 使用方向键切换 · X 编辑已关闭\";"
  print "}"
  skip=1; next
}
/^        if\(launcher_custom_source\(\)\)\{$/ {
  print "        text(b,210,359,27,proxy_mode_cn(st.proxy.mode),white,360);"
  print "        std::string proxy_addr=(st.proxy.host[0]&&st.proxy.port>0)?std::string(st.proxy.host)+\":\"+std::to_string(st.proxy.port):\"未设置代理服务器\";"
  print "        text(b,210,398,17,proxy_addr,st.proxy.mode==PROXY_MODE_DIRECT?muted:pink,760,1);"
  skip_proxy_ui=1; next
}
{ print }
' "$MAIN" > "$TMP"
mv "$TMP" "$MAIN"

sed -i 's/text(b,430,587,18,launcher_custom_source()?"X 编辑":"X 仅自定义",launcher_custom_source()?pink:muted,170);/text(b,430,587,18,(st.launcher_row==0\&\&launcher_custom_source())?"X 编辑自定义":"X 不编辑代理",(st.launcher_row==0\&\&launcher_custom_source())?pink:muted,190);/' "$MAIN"
sed -i 's/safe_text(b,s,68,466,2,launcher_custom_source()?"A START  X EDIT  Y TEST  PLUS EXIT":"A START  BUILTIN DIRECT  PLUS EXIT",white);/safe_text(b,s,68,466,2,"A START  X CUSTOM ONLY  Y TEST  PLUS EXIT",white);/' "$MAIN"

PLAYER="nxanime_source/player.cpp"
if ! grep -q 'const bool online_video_smooth' "$PLAYER"; then
  sed -i '/request.user_agent = "Mozilla\/5.0/a\    const bool online_video_smooth = request.referer.find("yichengwlkj.com") != std::string::npos || request.referer.find("rrmj.plus") != std::string::npos;' "$PLAYER"
fi

grep -q 'st.status="X 编辑仅用于自定义播放源"' "$MAIN"
grep -q 'st.proxy.mode=(ProxyMode)wrapi' "$MAIN"
grep -q 'X 不编辑代理' "$MAIN"
! grep -q '固定直连' "$MAIN"
grep -q 'const bool online_video_smooth' "$PLAYER"
