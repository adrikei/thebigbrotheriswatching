template_1 = "curl -A 'Mozilla/5.0 (X11; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0' https://www.insecam.org/en/byrating/?page="

for(i = 1; i<= 500; i++){
    console.log(template_1 + i + ' > insecam/page_' + i + '.html')
}