#!/bin/bash


echo -e "###### Gathering the JS Files - Wayback ######\n"

cat targets.txt | waybackurls >>waybacktmp && cat waybacktmp | grep -iE "\.js$" | uniq | sort >> jsfile_links.txt && rm waybacktmp

echo -e "###### Gathering the JS Files - Subjs ######\n"

prependme targets.txt https:// | subjs >> jsfile_links.txt

echo -e "###### Gathering the JS Files - Gospider ######\n"

gospider -S targets-go.txt -c 10 -d 1 -t 20 --timeout 0 >>tmp && cat tmp |grep "javascript" |cut -d"-" -f2 |cut -d" " -f2 | grep -iE "\.js" >> jsfile_links.txt && rm tmp
#cat $target | hakrawler -js -depth 2 -scope subs -plain >> jsfile_links.txt
echo -e "\n\e[36m[\e[32m+\e[36m]\e[92m Checking for live JsFiles-links\e[0m\n";
cat jsfile_links.txt | httpx -follow-redirects -silent -status-code | grep "[200]" | cut -d ' ' -f1 | sort -u > live_jsfile_links.txt


echo -e "\n\e[36m[\e[32m+\e[36m]\e[92m Started gathering Endpoints\e[0m\n";
interlace -tL live_jsfile_links.txt -threads 5 -c "echo 'Scanning _target_ Now' ; python3 /root/BB/tools/jsfscan/tools/LinkFinder/linkfinder.py -d -i _target_ -o cli >> endpoints.txt" -v


echo -e "\n\e[36m[\e[32m+\e[36m]\e[92m Started Finding Secrets in JSFiles\e[0m\n";
interlace -tL live_jsfile_links.txt -threads 5 -c "python3 /root/BB/tools/jsfscan/tools/SecretFinder/SecretFinder.py -i _target_ -o cli >> jslinksecret.txt" -v



echo -e "\n\e[36m[\e[32m+\e[36m]\e[92m Started to Gather JSFiles locally for Manual Testing\e[0m\n";
mkdir -p jsfiles
interlace -tL live_jsfile_links.txt -threads 5 -c "bash /root/BB/tools/jsfscan/tools/getjsbeautify.sh _target_" -v
echo -e "\n\e[36m[\e[32m+\e[36m]\e[92m Manually Search For Secrets Using gf or grep in out/\e[0m\n";



echo -e "\n\e[36m[\e[32m+\e[36m]\e[92m Started Gathering Words From JsFiles-links For Wordlist.\e[0m\n";
cat live_jsfile_links.txt | python3 /root/BB/tools/jsfscan/tools/getjswords.py >> temp_jswordlist.txt
cat temp_jswordlist.txt | sort -u >> jswordlist.txt
rm temp_jswordlist.txt



echo -e "\n\e[36m[\e[32m+\e[36m]\e[92m Started Finding Varibles in JSFiles For Possible XSS\e[0m\n";
cat live_jsfile_links.txt | while read url ; do bash /root/BB/tools/jsfscan/tools/jsvar.sh $url | tee -a js_var.txt ; done



echo -e "\n\e[36m[\e[32m+\e[36m]\e[92m Scanning JSFiles For Possible DomXSS\e[0m\n";
interlace -tL live_jsfile_links.txt -threads 5 -c "bash /root/BB/tools/jsfscan/tools/findomxss.sh _target_" -v



echo -e "\n\e[36m[\e[32m+\e[36m]\e[92m Generating Report!\e[0m\n";
bash /root/BB/tools/jsfscan/report.sh



mkdir Output
mv endpoints.txt jsfile_links.txt jslinksecret.txt live_jsfile_links.txt jswordlist.txt js_var.txt domxss_scan.txt report.html Output/ 2>/dev/null
mv jsfiles/ Output/

