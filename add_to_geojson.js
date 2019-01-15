
json = JSON.parse(fs.readFileSync('countries.geojson', 'utf-8'))

csv = fs.readFileSync('Country_Data_final_clean.csv', 'utf-8')

csv = csv.split('\n')

country_lines = csv.map(l => l.split(';'))

country_lines = country_lines.slice(0, country_lines.length-1)


countries = []
country_lines.map(c => countries.push({name: c[0], density: parseInt(c[3].replace(/\r/g, ''))}))


json.features.map(f => f.properties.density = (countries.filter(c => c.name === f.properties.name)[0]||{}).density)

fs.writeFileSync('countries_density.geojson', JSON.stringify(json), {encoding: 'utf-8'})
