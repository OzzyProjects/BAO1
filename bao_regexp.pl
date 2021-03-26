#!/usr/bin/perl
use strict;
#use warnings;
use Timer::Simple;

# IL FAUT INSTALLER LE MODULE TIMER::SIMPLE
# sudo cpan
# install Timer::Simple

binmode(STDOUT, ":utf8");

# on instancie un timer commencant à 0.0s par défaut
my $t = Timer::Simple->new();
# on lance le timer
$t->start;

# --------------------------------------------------------------------------------
# $ARGV[0] = repertoire dans lequel chercher les fichiers xml rss
# $ARGV[1] = code de la catégorie
# --------------------------------------------------------------------------------

# on recupere le premier argument (repertoire)
my $folder = $ARGV[0];
# on recupere le second argument (code de la catégorie)
my $code = $ARGV[1];

# liste de tous les fichiers xml rss correspondant à la catégorie (reference anonyme à un array)
my $xmls = [];

my $categories = {3208 => "une", 3210 => "international", 3214 => "europe", 3224 => "societe", 3232 => "idees", 3234 => "economie",
3236 => "actualite_medias", 3242 => "sport", 3244 => "planete", 3246 => "culture", 3260 => "livres", 3476 => "cinema",
3546 => "voyage", 6518 => "technologies", 8233 => "politique", "env_sciences" => "sciences"};

# si le code de la categorie est introuvable, on met fin au script
die "Code de categorie introuvable !\n" unless exists($categories->{$code});

# on ouvre les deux fichiers de resultats
open my $output_xml, ">:encoding(utf-8)", "$categories->{$code}.xml" or die "$!";
open my $output_txt, ">:encoding(utf-8)", "$categories->{$code}.txt" or die "$!";
            
# écriture de l'en-tete du fichier xml de sortie
print $output_xml "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
print $output_xml "<root>\n";

# on fait appel à la subroutine parcourir
&parcourir($folder);

# on parse les fichiers xml rss
&parsefiles;

sub parcourir{
    
    # on recupere l'argument de la subroutine
    my $folder = shift @_;
    # on supprime le / final si il existe
    $folder =~ s/\/$//;
    # on recupere les fichiers et dossier du repertoire
    opendir(DIR, $folder);
    # on liste tous les fichiers et dossiers du repertoire
    my @files = readdir(DIR);
    # on ferme le repertoire
    closedir(DIR);
    
    # pour chaque fichier/dossier
    foreach my $file(@files){
        
        next if $file =~ /^\.\.?$/;
        # on constitue le chemin d'acces complet du fichier/dossier
        my $f = $folder."/".$file;
        
        # si c'est un dossier, on fait appel à la récursivité
        if (-d $f){
            &parcourir($f);
        }
        
        # si c'est un fichier xml rss, on va appliquer un traitement XML::RSS
        # on l'ajoute au tableau @$xmls
        if (-f $f && $f =~ /$code.*\.xml/){
            push @$xmls, $f;
        }
    }
}

sub parsefiles{
    
    # reference anonyme sur hash (dictionnaire) ayant pour clé le titre et la description concaténés
    my $titres_descriptions = {};
    
    # pour chaque fichier xml rss correspondant à la catégorie
    foreach my $file(@$xmls){
        
        open my $input, "<:encoding(UTF-8)","$file" or die "$!";
        undef $/;
        my $ligne=<$input>; # lecture globale car $/ n'a plus de valeur
        while ($ligne=~/<item><title>(.+?)<\/title>.+?<description>(.+?)<\/description>/gs) {
            # l'option s dans la recherche permet de tenir compte des \n
            my $titre=&nettoyage($1);
            my $description=&nettoyage($2);
            my $date = format_date($file);
            
            # on ajoute le titre et la description dans le hash en tant que clé et ayant la valeur 1 par défaut
            my $title_desc = $titre."||".$description;
            $titres_descriptions->{$title_desc} = $date unless exists($titres_descriptions->{$title_desc});
        }
        
        close $input;
    }
    
    my $compteur = 1;
    
    foreach my $key(sort { $titres_descriptions->{$a} <=> $titres_descriptions->{$b} or $a cmp $b } keys %$titres_descriptions){
        
        # on recupere le titre et la description avec split avec comme séparateur ||
        # $t_d[0] = titre
        # $t_d[1] = description
        my @t_d = split(/\|\|/, $key);
        
        # on écrit les données dans le fichier xml
        print $output_xml "<item numero=\"$compteur\" date=\"$titres_descriptions->{$key}\"><titre>$t_d[0]</titre>\n";
        print $output_xml "<description>$t_d[1]</description>\n</item>\n";
        
        # on ecrit les données dans le fichier txt
        print $output_txt "$t_d[0]\n";
        print $output_txt "$t_d[1]\n";
        
        $compteur++;
    }
        
    # fin du fichier xml
    print $output_xml "</root>\n";
    
    # on ferme les fichiers de sortie
    close $output_xml;
    close $output_txt;
    
    # temps écoulé depuis le lancement du programme
    print "time so far: ", $t->elapsed, " seconds\n";
}

sub nettoyage {
	# quand on lance une procédure
	# perl range les arguments de la procédure dans une liste spéciale
	# qui s'appelle @_
	my $texte=shift @_;
	$texte=~s/<!\[CDATA\[//g;
	$texte=~s/\]\]>//g;
    $texte =~s/&nbsp/ /g;
	# ajout du point en fin de chaîne
	$texte=~s/$/\./g;
	$texte=~s/\.+$/\./g;
	return $texte;
}

sub format_date{
	
	my $file = shift;
	$file =~ m/(\d+)\/(\d+)\/(\d+)\//;
	return $1.$2.$3;
}
