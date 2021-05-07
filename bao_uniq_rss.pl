#!/usr/bin/perl
use strict;
#use warnings;
use XML::RSS;
# pour supprimer les doublons
use List::MoreUtils qw(uniq);
# pour le timer
use Timer::Simple;

# on ne travaille qu'en utf-8
use open qw/ :std :encoding(UTF-8)/;

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

# liste de tous les fichiers xml rss correspondant à la catégorie (reference anonyme à un array)
my $xmls = [];

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
    
    # liste contenant les titres + descriptions concanténés (reference anonyme à un array)
    my $titres_descriptions = [];
    
    # pour chaque fichier xml rss correspondant à la catégorie
    foreach my $file(@$xmls){
        
        # on parse le fichier xml en question
        my $rss=new XML::RSS;
        eval {$rss->parsefile($file); };
            
        if( $@ ) {
            $@ =~ s/at \/.*?$//s;               # remove module line number
            print STDERR "\nERROR in '$file':\n$@\n";
            next;
        }
        
        # on parcours chaque item du fichier xml d'entrée
        foreach my $item (@{$rss->{'items'}}){
                
            # on recupere les titres et description de l'item
            my $description=$item->{'description'};
            my $titre=$item->{'title'};
            # on nettoie le texte
            $titre = &nettoietexte($titre);
            $description = &nettoietexte($description);
            my $xml_file = $file;
            my $date = format_date($file);
            
            # on ajoute le titre et la description dans l'array @$titre_description
            my $title_desc = $titre."||".$description."||".$xml_file."||".$date;
            push @$titres_descriptions, $title_desc;
        }
    }
    
    # on supprime tous les doublons grace à uniq() qui renvoie un array de valeurs uniques
    my @unique = uniq @$titres_descriptions;

    # on crée un nouveau dictionnaire avec en valeur la date de publication
    my %hash_items = map {$_ =~ /^.+\|\|(.+)$/; $_ => $1;} @unique;
    
    my $compteur = 1;

    foreach my $key(sort { $hash_items{$a} <=> $hash_items{$b} or $a cmp $b } keys %hash_items){
        
        # on recupere le titre et la description avec split avec comme séparateur ||
        # $t_d[0] = titre
        # $t_d[1] = description
        my @t_d = split(/\|\|/, $key);
        
        # on écrit les données dans le fichier xml avec numero, date, et fichier pour l'item en question son titre et sa description
        print $output_xml "<item numero=\"$compteur\" date=\"$hash_items{$key}\" fichier=\"$t_d[2]\"><titre>$t_d[0]</titre>\n";
        print $output_xml "<description>$t_d[1]</description>\n</item>\n";
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

sub nettoietexte{   
    
    my $texte=shift;     
    $texte =~ s/&lt;/</g;     
    $texte =~ s/&gt;/>/g;     
    $texte =~ s/<a href[^>]+>//g;     
    $texte =~ s/<img[^>]+>//g;     
    $texte =~ s/<\/a>//g;     
    $texte =~ s/&#38;#39;/'/g;     
    $texte =~ s/&#38;#34;/"/g;     
    $texte =~ s/<[^>]+>//g;
    $texte =~ s/&nbsp/ /g;
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

