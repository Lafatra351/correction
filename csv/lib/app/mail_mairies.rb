# Ici sont mis les require nécessaires à la réalisation du projet
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'google_drive'
require 'csv'

# La classe mail englobe tous les différentes méthodes utilisées
class Mail

# La méthode get_townhall_urls permet d'aller sur la bonne page du site
# pour aller scraper les informations. Elle appelle la méthode get_townhall_email
def get_townhall_urls
  array_cities_emails = []
  doc = Nokogiri::HTML(open("http://www.annuaire-des-mairies.com/val-d-oise"))
    doc.css("a.lientxt").each do |city|
      townhall_url = "http://annuaire-des-mairies.com" + city["href"][1..-1]
      array_cities_emails << get_townhall_email(townhall_url)
    end
  puts array_cities_emails.inspect
  return array_cities_emails
end

# La méthode get_townhall_email permet de scraper les informations voulues.
# Ici nous scrapons la ville et l'email de chaque mairie du 95.
def get_townhall_email(townhall_url)
  doc = Nokogiri::HTML(open(townhall_url))
  email = doc.xpath("/html/body/div/main/section[2]/div/table/tbody/tr[4]/td[2]").text
  city = doc.xpath("/html/body/div/main/section[1]/div/div/div/h1").text.split.first
  return Hash[city, email]
end

# La méthode save_as_JSPON nous permet de créer / modifier un fichier contenant
# toutes les hash de toutes les mairies que nous avons scrapées. Ce document 
# est en mode JSON et il ne reste pas très clair et facile à utiliser.
def save_as_JSON(get_townhall_urls)
  File.open("db/email.json","w") do |f|
    f.write(get_townhall_urls.to_json)
  end
end

# La méthode save_as_spreadsheet nous permet de créer / modifier un fichier
# contenant toutes les hash de toutes les mairies que nous avons scrapées.
# Ce fichier est directement mis dans un google sheet créé au préalable.
# Il y a une colonne pour les mairies et une colonne pour les adresses mail.
def save_as_spreadsheet(get_townhall_urls)
  session = GoogleDrive::Session.from_config("config.json")
  ws = session.spreadsheet_by_key("1Z3bJYVtkvbXnXamrD7GRFw9uak1i4aUha-69bhrIaPU").worksheets[0]
    
  array_cities_emails_spreadsheet = get_townhall_urls 
  i = 1
# On pourrait aussi utiliser each_with_index |x, i| pour ne pas à avoir à mettre le i = 1 et le i += 1.
  array_cities_emails_spreadsheet.each do |x|
    ws[i, 1] = x.keys.join
    ws[i, 2] = x.values.join
    i += 1
  end
  # Attention ne pas mettre ws.save dans la boucle each sinon cela va faire autant de demandes à 
  # Google API qu'il y a de couples (keys, values)
  ws.save 
end

# La méthode save_as_csv nous permet de créer / modifier un fichier
# contenant toutes les hash de toutes les mairies que nous avons scrapées.
# Ce fichier est en mode CSV, le format le plus pratique pour récupérer les données.
# Il y a une colonne pour les mairies et une colonne pour les adresses mail.
def save_as_csv(get_townhall_urls)

  CSV.open("db/emails.csv", "wb") do |f|
    get_townhall_urls.each do |ou|
      f << [ou.keys.join, ou.values.join]
    end 
  end 
end

# La méthode perform qui va nous permettre d'éxecuter toutes les méthodes que 
# nous avons crées dans notre classe Mail.
def perform 
  get_townhall_urls
  save_as_JSON(get_townhall_urls)
  save_as_spreadsheet(get_townhall_urls)
  save_as_csv(get_townhall_urls)
end

end

