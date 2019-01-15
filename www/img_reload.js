imgurl = document.getElementById('js_script').getAttribute('data_url')
id_ = document.getElementById('js_script').getAttribute('data_id')

if(typeof interval !== 'undefined') clearInterval(interval)
if(typeof intervals !== 'undefined') intervals.map(i => clearInterval(i))
interval = setInterval(() => {
    if(imgurl.indexOf('COUNTER') > -1){
        cam_img = document.getElementById(`cam-snapshot${id_}`)
        if(cam_img){
            cam_img.src = `${imgurl}&timestamp=${new Date().getTime()}`
            console.log(`${imgurl}&timestamp=${new Date().getTime()}`)
        }
    }
}, 2000)