/*********************************************************************************************************/
/*                                         Passage de SAS vers R                                         */
/*********************************************************************************************************/

/* A FAIRE :
- Transformer la dur�e en mois et en ann�e
- merge, append base, set
- expand.grid et cross join
- macro pour stock � la fin de l'ann�e
- substr � manipuler !!! */

/* Proc print
   Test ligne par ligne
   Autres fonctions de manipulation de cha�nes de caract�res
*/


/* Cr�ation d'une base de donn�es SAS d'exemple */
/* Donn�es fictives sur des formations */

data Donnees;
  infile cards dsd dlm='|';
  format Identifiant $3. Sexe_red 1. CSP $1. Niveau $30. Date_naissance ddmmyy10. Date_entree ddmmyy10. Duree Note_Contenu Note_Formateur Note_Moyens
         Note_Accompagnement Note_Materiel poids_sondage;
  input Identifiant $ Sexe_red CSP $ Niveau $ Date_naissance :ddmmyy10. Date_entree :ddmmyy10. Duree Note_Contenu Note_Formateur Note_Moyens
        Note_Accompagnement Note_Materiel poids_sondage;
  cards;
  173|2|1|Qualifie|17/06/1998|01/01/2021|308|12|6|17|4|19|117.1
  173|2|1|qualifie|17/06/1998|01/01/2022|365|6||12|7|14|98.3
  173|2|1|qualifie|17/06/1998|06/01/2022|185|8|10|11|1|9|214.6
  173|2|1|Qualifie|17/06/1998|02/01/2023|365|14|15|15|10|8|84.7
  174|1|1|qualifie|08/12/1984|17/08/2021|183|17|18|20|15|12|65.9
  175|1|1|qualifie|16/09/1989|21/12/2022|730|5|5|8|4|9|148.2
  198|2|4|Non qualifie|17/03/1987|28/07/2022|30|10|10|10|16|8|89.6
  198|2|4|Qualifie|17/03/1987|17/11/2022|164|11|7|6|14|13|100.3
  198|2|4|Qualifie|17/03/1987|21/02/2023|365|9|20|3|4|17|49.3
  168|1|2|Qualifie|30/07/2002|04/09/2019|365|18|11|20|13|15|148.2
  211|2|3|Non qualifie||17/12/2021|135|16|16|15|12|9|86.4
  278|1|5|Qualifie|10/08/1948|07/06/2018|365|14|10|6|8|12|99.2
  347|2|5|Qualifie|13/09/1955||180|12|5|7|11|12|105.6
  112|1|3|Non qualifie|13/09/2001|02/03/2022|212|3|10|11|9|8|123.1
  112|1|3|Non qualifie|13/09/2001|01/03/2021|365|7|13|8|19|2|137.4
  112|1|3|Non qualifie|13/09/2001|01/12/2023|365||||||187.6
  087|1|3|Non qualifie|||365||||||87.3
  087|1|3|Non qualifie||31/10/2020|365||||||87.3
  099|1|3|qualifie|06/06/1998|01/03/2021|364|12|11|10|12|13|169.3
  099|1|3|qualifie|06/06/1998|01/03/2022|364|12|11|10|12|13|169.3
  099|1|3|qualifie|06/06/1998|01/03/2023|364|12|11|10|12|13|169.3
  187|2|2|qualifie|05/12/1986|01/01/2022|364|10|10|10|10|10|169.3
  187|2|2|qualifie|05/12/1986|01/01/2023|364|10|10|10|10|10|234.1
  689|1|1||01/12/2000|06/11/2017|123|9|7|8|13|16|189.3
  765|1|4|Non qualifie|26/12/1995|17/04/2020|160|13|10|12|18|10|45.9
  765|1|4|Non qualifie|26/12/1995|17/04/2020|160|13|10|12|18|10|45.9
  765|1|4|Non qualifie|26/12/1995|17/04/2020|160|13|10|12|18|10|45.9
  ;
run;


/* Chemin du bureau de l'utilisateur */
/* On vide la log */
dm "log; clear; ";
/* On r�cup�re d�j� l'identifiant de l'utilisateur */
%let user = &sysuserid;
/* Chemin proprement dit */
%let bureau = C:\Users\&user.\Desktop;
libname bur "&bureau.";


/* Affichage de l'ann�e */
%let an = %sysfunc(year(%sysfunc(today())));
/* & (esperluette) indique � SAS qu'il doit remplacer an par sa valeur d�finie par le %let */
%put Ann�e : &an.;
/* Autre possibilit� */
data _null_;call symput('annee', strip(year(today())));run;
%put Ann�e (autre m�thode) : &annee.;
/* Ann�e pass�e */
%put Ann�e pass�e : %eval(&an. - 1);


/***************************************************** Informations sur la base de donn�es *****************************************************/

/* Extraire les x premi�res lignes de la base (10 par d�faut) */
%let x = 10;
proc print data = Donnees (firstobs = 1 obs = &x.);run;
/* Ou alors */
data Lignes&x.;set Donnees (firstobs = 1 obs = &x.);proc print;run;

/* On renomme la variable sexe_red en sexe */
data Donnees;
  set Donnees (rename = (sexe_red = sexe));
run;

/* Nombre de lignes et de colonnes dans la base */
/* Nombre de lignes */
proc sql;select count(*) as Nb_Lignes from Donnees;quit;
/* Liste des variables de la base dans la base Var */
proc contents data = Donnees out = Var noprint;run;
/* Nombre de colonnes */
proc sql;select count(*) as Nb_Colonnes from Var;run;
/* Liste des variables par ordre d'apparition dans la base */
proc sql;select name into :nom_col separated by " " from Var order by varnum;run;
/* On affiche les noms des variables */
%put Liste des variables : &nom_col.;
/* On supprime la base Var temporaire */
proc datasets lib = Work nolist;delete Var;run;


/* Manipuler des lignes et des colonnes */
/* Formater les modalit�s des valeurs */
proc format;
  value sexef
  1 = "Homme"
  2 = "Femme";

  value agef
  low-<26 = "1. De 15 � 25 ans"
  26<-<50 = "2. De 26 � 49 ans"
  50-high = "3. 50 ans ou plus";

  value $ cspf
  '1' = "Cadre"
  '2' = "Profession interm�diaire"
  '3' = "Employ�"
  '4' = "Ouvrier"
  '5' = "Retrait�";
run;

/* Utiliser les formats */
data Donnees;
  set Donnees;
  /* Exprimer dans le format sexef (Hommes / Femmes) */
  Sexef = put(Sexe, sexef.);
run;

/* Ajouter, transformer, supprimer, s�lectionner, conserver des colonnes */
data Femmes;
  /* S�lection de colonnes */
  set Donnees (keep = identifiant Sexe note_contenu Sexef);
  /* S�lection de lignes respectant une certaine condition */
  if Sexef = "Femme";
  /* Cr�ation de colonne */
  note2 = note_contenu / 20 * 5;
  /* Suppression de colonnes */
  drop Sexe;
  /* Selection de colonnes */
  keep identifiant note_contenu note2 Sexef;
run;

/* Variables commen�ant par le mot note */
proc contents data = Donnees out = Var noprint;run;
proc sql;select name into :var_notes separated by " " from Var where substr(upcase(name), 1, 4) = "NOTE" order by varnum;run;
proc datasets lib = Work nolist;delete Var;run;
data Donnees_Notes;set Donnees (keep = &var_notes.);run;

/* Cr�ation de variables conditions : if else if => ifelse ou case_when en R */
data Donnees;set Donnees;
  /* 1�re solution */
  format Civilite $20.;
  if      Sexe = 2 then Civilite = "Mme";
  else if Sexe = 1 then Civilite = "Mr";
  else                  Civilite = "Inconnu";
  /* 2e solution */
  format Civilite2 $20.;
  select;
    when      (Sexe = 2) Civilite2 = "Femme";
    when      (Sexe = 1) Civilite2 = "Homme";
    otherwise            Civilite2 = "Inconnu";
  end;
  /* 3e solution (do - end) */
  if      Sexe = 2 then do;
    Civilite = "Mme";Civilite2 = "Femme";
  end;
  else if Sexe = 1 then do;
    Civilite = "Mr";Civilite2 = "Homme";
  end;
  else do;
    Civilite = "Inconnu";Civilite2 = "Inconnu";
  end;
run;

/* Manipuler les dates */
%let sixmois = %sysevalf(365.25/2); /* On utilise %sysevalf et non %eval pour des calculs avec des macro-variables non enti�res */
%put sixmois : &sixmois.;
data Donnees;
  set Donnees;
  /* �ge � l'entr�e dans le dispositif */
  Age = intck('year', date_naissance, date_entree);
  /* �ge format� */
  Agef = put(Age, agef.);
  /* Date de sortie du dispositif : ajout de la dur�e � la date d'entr�e */
  format date_sortie ddmmyy10.;
  date_sortie = intnx('day', date_entree, duree);  
  /* Deux mani�res de cr�er une indicatrice 0/1 */
  /* La date de sortie est apr�s le 31 d�cembre de l'ann�e */
  if date_sortie > "31dec&an."d then apres_31_decembre = 1;else apres_31_decembre = 0;
  /* Ou alors */
  apres_31_decembre = (date_sortie > "31dec&an."d);
  /* La dur�e du contrat est-elle sup�rieure � 6 mois ? */
  Duree_Sup_6_mois = (Duree >= &sixmois.);
  /* Deux mani�res de cr�er une date */
  format Decembre_31_&an._a Decembre_31_&an._b ddmmyy10.;
  Decembre_31_&an._a = "31dec&an."d;
  Decembre_31_&an._b = mdy(12, 31, &an.); /* mdy pour month, day, year (pas d'autre alternative, ymd par exemple n'existe pas) */
  /* Date 6 mois apr�s la sortie */
  format Date_6mois ddmmyy10.;
  Date_6mois = intnx('month', date_sortie, 6);
run;
/* Ventilation pond�r�e (cf. infra) */
proc freq data = Donnees;tables apres_31_decembre;weight poids_sondage;run;

/* Mettre un 0 devant un nombre */
data Zero_devant;set Donnees (keep = date_entree);
  /* Obtenir le mois et la date */
  Mois = month(date_entree);
  Annee = year(date_entree);
  /* Mettre le mois sur 2 positions (avec un 0 devant si le mois <= 9) : format pr�d�fini z2. */
  Mois_a = put(Mois, z2.);
  drop Mois;
  rename Mois_a = Mois;
run;

/* On souhaite r��xprimer toutes les notes sur 100 et non sur 20 */
%let notes = Note_Contenu   Note_Formateur Note_Moyens     Note_Accompagnement     Note_Materiel;
/* On supprime les doubles blancs entre les variables */
%let notes = %sysfunc(compbl(&notes.));
%put &notes;
/* 1�re solution : avec les array */
data Sur100_1;
  set Donnees;
  array variables (*) &notes.;
  do increment = 1 to dim(variables);
    variables[increment] = variables[increment] / 20 * 100;
  end; 
  drop increment;
run;
/* 2e solution : avec une macro */
data Sur100_2;
  set Donnees;
  %macro Sur100;
    %do i = 1 %to %sysfunc(countw(&notes.));
	  %let note = %scan(&notes., &i.);
	  &note. = &note. / 20 * 100;
	%end;
  %mend Sur100;
  %Sur5;
run;
/* 3e solution : l'�quivalent des list-comprehension de Python en SAS */
data Sur100_3;
  set Donnees;
  %macro List_comprehension;
    %do i = 1 %to %sysfunc(countw(&notes.));
      %let j = %scan(&notes., &i.);
	    &j. = &j. / 20 * 100
	%end;);;
  %mend List_comprehension;
  %List_comprehension;
run;



/********************************************************** Manipuler des cha�nes de caract�res ***************************************************/

/* Fonction tranwrd (translate word) => R = grepl, upcase, lowcase, length */
data Donnees;
  set Donnees;
  /* Premi�re lettre en majuscule */
  Niveau = propcase(Niveau);
  /* On transforme une cha�ne de caract�res en une autre (Qualifie en Qualifi�) */
  Niveau = tranwrd(Niveau, "Qualifie", "Qualifi�");
  /* On exprime la CSP en texte dans une variable CSPF avec le format */
  format CSPF $100.;
  CSPF = put(CSP, $cspf.);
  /* En majuscule */
  CSP_majuscule = upcase(CSPF);
  /* En minuscule */
  CSP_minuscule = lowcase(CSPF);
  /* Nombre de caract�res dans une cha�ne de caract�res => nchar en R */
  taille_id = length(identifiant);
run;

/* Manipuler des cha�nes de caract�res => R = gsub, grepl etc. */
data Exemple_chaines;
  Texte = "              Ce   Texte   m�riterait   d �tre   corrig�                  ";
  Texte1 = "Je m'appelle";
  Texte2 = "SAS";
run;
data Exemple_chaines;set Exemple_chaines;
  /* Enlever les blancs au d�but et � la fin de la cha�ne de caract�re */
  Enlever_Blancs_Initiaux = strip(Texte);
  /* Enlever les doubles blancs dans la cha�ne de caract�res */
  Enlever_Blancs_Entre = compbl(Enlever_Blancs_Initiaux);
  /* Enlever doubles blancs */
  /* REVOIR !!!!! */
  Enlever_Doubles_Blancs = compress(Texte, "  ", "t");
  /* Trois m�thodes pour concat�ner des cha�nes de caract�res */
  Concatener  = Texte1||" "||Texte2;
  Concatener2 = Texte1!!" "!!Texte2;
  Concatener3 = catx(" ", Texte1, Texte2);
  /* Extraire les 2e, 3e et 4e caract�res de Concatener */
  /* 2 correspond � la position du 1er caract�re � r�cup�rer, 3 le nombre total de caract�res � partir du point de d�part */
  extrait = substr(Concatener, 2, 3);
  /* Transformer plusieurs caract�res diff�rents */
  chaine = "���������";
  /* On transforme le � en e, le � en a, le � en i, ... */
  chaine_sans_accent = translate(chaine, "eeeeaacio", "���������");
run;
proc print data = Exemple_chaines;run;

/* Transformer le format d'une variable */
/* put et input */
data Donnees;
  set Donnees;
  /* Transformer la variable Sexe en caract�re => R = as.character() */
  Sexe_car = put(Sexe, $1.);
  /* Transformer la variable Sexe_car en num�rique => R = as.numeric() */
  Sexe_num = input(Sexe_car, 1.);
run;

/* Arrondir une valeur num�rique */
data Arrondis;set Donnees (keep = Poids);
  /* Arrondi � l'entier le plus proche */
  poids_arrondi_0 = round(poids, 0.0);
  /* Arrondi � 1 chiffre apr�s la virgule */
  poids_arrondi_1 = round(poids, 0.1);
  /* Arrondi � 2 chiffre apr�s la virgule */
  poids_arrondi_2 = round(poids, 0.2);
  /* Arrondi � l'entier inf�rieur */
  poids_inf = floor(poids);
  /* Arrondi � l'entier inf�rieur */
  poids_inf = ceil(poids);  
run;



/**************************************************************** Gestion ligne par ligne ****************************************************************/

/* Num�ro de l'observation */
data Donnees;set Donnees;
  Num_observation = _n_;
run;
/* Autre solution */
proc sql noprint;select count(*) into :nbLignes from Donnees;quit;
data numLigne;do Num_observation = 1 to &nbLignes.;output;end;run;
/* Le merge "simple" (sans by) va seulement concat�ner les deux bases l'une � c�t� de l'autre */
data Donnees;
  merge Donnees numLigne;
run;


/* Num�ro du contrat de chaque individu, contrat tri� par date de survenue */
proc sort data = Donnees;by identifiant date_entree;run;
data Donnees;set Donnees;
  by identifiant date_entree;
  retain numero_contrat 0;
  if first.identifiant then numero_contrat = 1;
  else numero_contrat = numero_contrat + 1;
run;
/* Pour trier les colonnes */
data Donnees;retain identifiant date_entree numero_contrat Num_observation;set Donnees;run;

/* 2e contrat de l'individu (et rien si l'individu a fait 1 seul contrat */
data Deuxieme_Contrat;set Donnees;if numero_contrat = 2;run;
data Deuxieme_Contrat;set Donnees (where = (numero_contrat = 2));run;

/* Le premier contrat, le dernier contrat, ni le premier ni le dernier contrat de chaque individu ... */
proc sort data = Donnees;by identifiant date_entree;run;
data Donnees;set Donnees;
  by identifiant date_entree;
  Premier_Contrat = (first.identifiant = 1);
  Dernier_Contrat = (last.identifiant = 1);
  Ni_Prem_Ni_Der  = (first.identifiant = 0 and last.identifiant = 0);
  Doublon         = (first.identifiant = 0 or first.identifiant = 0)
run;

/* Cr�er une base avec les seuls premiers contrats, et une base avec les seuls derniers contrats */
proc sort data = Donnees;by identifiant date_entree;run;
data Premier_Contrat Dernier_Contrat;
  set Donnees;
  by identifiant date_entree;
  if first.identifiant then output Premier_Contrat;
  if last.identifiant then output Dernier_Contrat;
run;


/* La date de fin du contrat pr�c�dent */
proc sort data = Donnees;by identifiant date_entree;run;
data DonneesBon;set Donnees;
  by identifiant date_entree;  
  format Date_fin_1 ddmmyy10.;
  Date_fin_1 = lag(Date_sortie);
  if first.identifiant then Date_fin_1 = .;
run;


/* ATTENTION au lag DANS UNE CONDITION IF (cf. document) */
proc sort data = Donnees;by identifiant date_entree;run;
data Lag_Bon;set Donnees (keep = identifiant date_entree date_sortie);
  format date_sortie_1 lag_faux lag_bon ddmmyy10.;
  /* Erreur */
  if date_entree = lag(date_sortie) + 1 then lag_faux = lag(date_sortie) + 1;
  /* Bonne �criture */
  date_sortie_1 = lag(date_sortie);
  if date_entree = date_sortie_1 + 1 then lag_bon = date_sortie_1 + 1;
run;

/* Personnes qui ont suivi � la fois une formation qualifi�e et une formation non qualifi�e */
proc sql;
  create table Qualif_Non_Qualif as
  select *
  from Donnees
  group by identifiant
  having sum((Niveau = "Non qualifie")) >= 1 and sum((Niveau = "Non qualifie")) >= 1;
quit;


/* Transposer une base */
proc freq data = Donnees;table Sexef * cspf / out = Nb;run;
proc sort data = Nb;by cspf Sexef;run;
proc print data = Nb;run;
proc transpose data = Nb out = transpose;by cspf;var count;id Sexef;run;
data transpose;set transpose (drop = _name_ _label_);run;
proc print data = transpose;run;



/******************************************************************* Les valeurs manquantes ************************************************************/

/* Rep�rer les valeurs manquantes */
data Missing;set Donnees;
  /* 1�re solution */
  if missing(age) or missing(Niveau) then missing1 = 1;else missing1 = 0;
  if age = . or Niveau = '' then missing2 = 1;else missing2 = 0;
  keep Age Niveau Missing1 Missing2;
run;

/* Incidence des valeurs manquantes : 1er cas */
/* En SAS, les valeurs manquantes sont des nombres n�gatifs faibles */
data Valeur_Manquante;set Donnees;
  Jeune_Correct   = (15 <= Age <= 25);
  Jeune_Incorrect = (Age <= 25);
run;
/* Lorsque Age est manquant (missing), Jeune_Correct vaut 0 mais Jeune_Incorrect vaut 1 */
/* En effet, pour SAS, un Age manquant est une valeur inf�rieure � 0, donc bien inf�rieure � 25.
   Donc la variable Jeune_Incorrect vaut bien 1 pour les �ges inconnus */
proc print data = Valeur_Manquante (keep = Age Jeune_Correct Jeune_Incorrect where = (missing(Age)));run;




/******************************************************************* Les tris ************************************************************************/

/* Trier la base par ligne (individu et date de d�but de la formation) par ordre d�croissant : 2 possibilit�s */
proc sort data = Donnees;by Identifiant Date_entree;run;
proc sql;create table Donnes as select * from Donnees order by Identifiant, Date_entree;quit;
/* Idem par ordre croissant d'identifiant et ordre d�croissant de date d'entr�e */
proc sort data = Donnees;by Identifiant Date_entree descending;run;
proc sql;create table Donnes as select * from Donnees order by Identifiant, desc Date_entree;quit;



/* Trier la base par colonne (noms de variables) */
/* On met identifiant date_entree et date_sortie au d�but de la base */
%let colTri = identifiant date_entree date_sortie;
data Donnees;
  retain &colTri.;
  set Donnees;
run;
/* Autre solution */
proc sql;
  create table Donnees as
  /* On remplace les blancs entre les mots par des virgules pour la proc SQL */
  /* Dans la proc SQL, les variables doivent �tre s�par�es par des virgules */
  select %sysfunc(tranwrd(&colTri., %str( ), %str(, ))), * from Donnees;
quit;


/* Incidence des valeurs manquantes dans les tris : 2e cas */
/* Les valeurs manquantes sont situ�es en premier dans un tri par ordre croissant ... */
proc sort data = Donnees;by identifiant date_entree;run;proc print;run;
/* ... et en dernier selon un tri par ordre d�croissant */
proc sort data = Donnees;by identifiant descending date_entree;run;proc print;run;
/* En effet, les valeurs manquantes sont consid�r�es comme des valeurs n�gatives */



/******************************************************************* Les doublons ********************************************************************/

/* Rep�rage et �liminiation des doublons */

/* Rep�rage des doublons */

/* On r�cup�re d�j� la derni�re variable de la base (on en aura besoin plus loin) */
proc contents data = Donnees out = Var noprint;run;
proc sql noprint;select name into :derniere_var from Var where varnum = (select max(varnum) from Var);quit;
/* 1�re m�thode */
proc sort data = Donnees;by &nom_col.;run;
data Doublons;set Donnees;by &nom_col.;
  if first.&derniere_var. = 0 or last.&derniere_var. = 0;
run;

/* 2e m�thode */
/* On remplace les blancs entre les mots par des virgules pour la proc sql */
/* Dans la proc SQL, les variables doivent �tre s�par�es par des virgules */
%let nom_col_sql = %sysfunc(tranwrd(&nom_col., %str( ), %str(, )));
/* On groupe par toutes les colonnes, et si on aboutit � strictement plus qu'une ligne, c'est un doublon */
proc sql;create table Doublons as select * from Donnees group by &nom_col_sql. having count(*) > 1;quit;


/* Suppression des doublons */
/* 1�re m�thode */
proc sort data = Donnees nodupkey;by &nom_col.;run;

/* 2e m�thode, avec first. et last. (cf. infra) */
/* On r�cup�re d�j� la derni�re variable de la base (on en aura besoin plus loin) */
proc contents data = Donnees out = Var noprint;run;
proc sql noprint;select name into :derniere_var from Var where varnum = (select max(varnum) from Var);quit;
proc sql noprint;select name into :nom_col separated by " " from Var order by varnum;quit;
%put Derni�re variable de la base : &derniere_var.;
%put &nom_col.;
proc sort data = Donnees;by &nom_col.;run;
data Donnees;set Donnees;by &nom_col.;if first.&derniere_var.;run;



/**************************************************************** Les jointures de bases ****************************************************************/

/* Les jointures */
/* On suppose que l'on dispose d'une base suppl�mentaire avec les dipl�mes des personnes */
data Diplome;
  infile cards dsd dlm='|';
  format Identifiant $3. Diplome $50.;
  input Identifiant $ Diplome $;
  cards;
  173|Bac
  168|Bep-Cap
  112|Bep-Cap
  087|Bac+2
  689|Bac+2
  765|Pas de dipl�me
  112|Bac
  999|Bac
  554|Bep-Cap
  ;
run;
data Jointure;set Donnees (keep = Identifiant Sexe Age);run;

/* 1. Inner join : les seuls identifiants communs aux deux bases */
/* Le tri pr�alable des bases de donn�es � joindre par la variable de jointure est n�cessaire avec la strat�gie merge */
proc sort data = Diplome;by identifiant;run;
proc sort data = Jointure;by identifiant;run;
data Inner_Join1;
  merge Jointure (in = a) Diplome (in = b);
  by identifiant;
  if a and b;
run;
/* Le tri pr�alable des bases de donn�es � joindre n'est pas n�cessaire avec la jointure SQL */
proc sql;
  create table Inner_Join2 as
  select * from Jointure a inner join Diplome b on a.identifiant = b.identifiant
  order by a.identifiant;
quit;
proc print data = Inner_Join1;run;
proc sql;select count(*) from Inner_Join1;quit;

/* 2. Left join : les identifiants de la base de gauche */
/* Le tri pr�alable des bases de donn�es � joindre par la variable de jointure est n�cessaire avec la strat�gie merge */
proc sort data = Diplome;by identifiant;run;
proc sort data = Jointure;by identifiant;run;
data Left_Join1;
  merge Jointure (in = a) Diplome (in = b);
  by identifiant;
  if a;
run;
/* Le tri pr�alable des bases de donn�es � joindre n'est pas n�cessaire avec la jointure SQL */
proc sql;
  create table Left_Join2 as
  select * from Jointure a left join Diplome b on a.identifiant = b.identifiant
  order by a.identifiant;
quit;
proc print data = Left_Join1;run;
proc sql;select count(*) from Left_Join1;quit;

/* 3. Full join : les identifiants des deux bases */
/* Le tri pr�alable des bases de donn�es � joindre par la variable de jointure est n�cessaire avec la strat�gie merge */
proc sort data = Diplome;by identifiant;run;
proc sort data = Jointure;by identifiant;run;
data Full_Join1;
  merge Jointure (in = a) Diplome (in = b);
  by identifiant;
  if a or b;
run;
/* Le tri pr�alable des bases de donn�es � joindre n'est pas n�cessaire avec la jointure SQL */
proc sql;
  create table Full_Join2 as
  select coalesce(a.identifiant, b.identifiant) as Identifiant, * from Jointure a full outer join Diplome b on a.identifiant = b.identifiant
  order by calculated identifiant;
quit;
proc print data = Full_Join1;run;
proc sql;select count(*) from Full_Join1;quit;

/* 4. Cross join : toutes les combinaisons possibles de CSP, sexe et Diplome */
proc sql;
  select *
  from (select distinct CSPF from Donnees) cross join (select distinct Sexef from Donnees) cross join (select distinct Diplome from Diplome)
  order by CSPF, Sexef, Diplome;
quit;




/**************************************************************** Statistiques descriptives ****************************************************************/

/* Moyenne de chaque note */
%let notes = Note_Contenu Note_Formateur Note_Moyens Note_Accompagnement Note_Materiel;
proc means data = Donnees mean;var &notes.;run;
/* Somme, moyenne, m�diane, minimum, maximum, nombre de donn�es */ 
proc means data = Donnees sum mean median min max n;var &notes.;run;
/* Notes pond�r�es (poids de sondage) */
proc means data = Donnees sum mean median min max n;var &notes.;weight poids_sondage;run;

/* Tableaux de fr�quence : proc freq */
proc freq data = Donnees;
  tables Sexe CSP / missing;
  format Sexe sexef. CSP $cspf.;
  /*weight poids_sondage;*/
run;
/* Tableau de contingence : proc freq */
proc freq data = Donnees;
  tables Sexe * CSP / missing;
  format Sexe sexef. CSP $cspf.;
  *weight poids_sondage;
run;
/* Tableau de contingence (tableau crois�) avec sans les proportions lignes, colonnes et totales */
proc freq data = Donnees;
  tables CSP * Sexe  / missing nofreq norow nocol;
  format Sexe sexef. CSP $cspf.;
  *weight poids_sondage;
run;

/* Moyenne des notes par individu */
%let notes = Note_Contenu Note_Formateur Note_Moyens Note_Accompagnement Note_Materiel;
data Donnees;
  set Donnees;
  /* 1�re solution */
  Note_moyenne    = mean(of &notes.);
  /* 2e solution */
  Note_moyenne2   = sum(of &notes.) / %sysfunc(countw(&notes.));
  /* 3e solution : l'�quivalent des list-comprehension de Python en SAS */
  %macro List_comprehension;
    Note_moyenne3 = mean(of %do i = 1 %to %sysfunc(countw(&notes.));
	                      %let j = %scan(&notes., &i.);
						  &j.
						 %end;);;
  %mend List_comprehension;
  %List_comprehension;
run;
/* Note moyenne (moyenne des moyennes), non pond�r�e et pond�r�e */
proc means data = Donnees mean;var Note_moyenne;run;
proc means data = Donnees mean;var Note_moyenne;weight poids_sondage;run;

/* La note donn�e est-elle sup�rieure � la moyenne ? */
/* On cr�e une macro-variable SAS � partir de la valeur de la moyenne */
proc sql noprint;select mean(Note_moyenne) into :moyenne from Donnees;quit;
data Donnees;set Donnees;
  Note_Superieure_Moyenne = (Note_moyenne > &moyenne.);
run;
proc freq data = Donnees;tables Note_Superieure_Moyenne;weight poids_sondage;run;

/* D�ciles et quartiles de la note moyenne */
/* Par la proc means */
proc means data = Donnees StackODSOutput Min P10 P20 P30 P40 Median P60 P70 Q3 P80 P90 Max Q1 Median Q3;
  var Note_moyenne;
  ods output summary = Deciles_proc_means;
run;
/* Par la proc univariate */
proc univariate data = Donnees;
  var Note_moyenne;
  output out = Deciles_proc_univariate pctlpts=00 to 100 by 10 25 50 75 PCTLPRE=_; 
run;

/* Tableaux de r�sultats */
/* Note moyenne par croisement de CSP (en ligne) et de Sexe x Niveau (en colonne) */
proc tabulate data = Donnees;
  class cspf sexef Niveau;
  var note_moyenne;
  table (cspf all = "Ensemble"), (sexef * Niveau) * (note_moyenne) * mean;
run;
/* CSP et sexe en ligne */
proc tabulate data = Donnees;
  class cspf sexef Niveau;
  var note_moyenne;
  table (cspf * sexef all = "Ensemble"), (Niveau) * (note_moyenne) * mean;
run;




/**************************************************************** Macros SAS ****************************************************************/

/* On recherche toutes les valeurs de CSP diff�rentes et on les met dans une variable.
   On appelle la proc SQL :
   - utilisation du quit et non run � la fin
   - on r�cup�re toutes les valeurs diff�rentes de CSP, s�par�s par un espace (separated by)
   - s'il y a un espace dans les noms, on le remplace par _ 
   - on les met dans la macro-variable liste_csp
   - on trier la liste par valeur de CSP */
/* On cr�e une variable de CSP format� sans les accents et les espaces */
data Donnees;set Donnees;
  /* SAS ne pourra pas cr�er des bases de donn�es avec des noms accentu�s */
  /* On supprime dans le nom les lettres accentu�s. On le fait avec la fonction Translate */
  CSPF2 = tranwrd(strip(CSPF), " ", "_");
  CSPF2 = translate(CSPF2, "eeeeaacio", "���������");
run;

/* Boucles et macros en SAS */
/* Les boucles ne peuvent �tre utilis�es que dans le cadre de macros */
/* Ouverture de la macro */
%macro Boucles(base = Donnees, var = CSPF2);
  /* Les modalit�s de la variable */
  proc sql noprint;select distinct &var. into :liste separated by " " from &base. order by &var.;quit;
  /* On affiche la liste de ces modalit�s */
  %put &liste.;
  /* %let permet � SAS d'affecter une valeur � une variable en dehors d'une manipulation de base de donn�es */
  /* %sysfunc indique � SAS qu'il doit utiliser la fonction countw dans le cadre d'une macro (pas important) */
  /* countw est une fonction qui compte le nombre de mots (s�par�s par un espace) d'une cha�ne de caract�res => on compte le nombre de CSP diff�rentes */
  %let nb = %sysfunc(countw(&liste.));
  %put Nombre de modalit�s diff�rentes : &nb.;
  /* On it�re pour chaque CSP diff�rente ... */
  %do i = 1 %to &nb.;
    /* %scan : donne le i-�me mot de &liste. (les mots sont s�par�s par un espace) : on r�cup�re donc la CSP num�ro i */
    %let j = %scan(&liste., &i.);
	%put Variable : &j.;
	/* On cr�e une base avec seulement les individus de la CSP correspondante */
	data &var.;set Donnees;if &var. = "&j.";run;
  %end;
/* Fermeture de la macro */
%mend Boucles;
/* Lancement de la macro */
%Boucles(base = Donnees, var = CSPF2);


/* It�rer sur toutes les ann�es et les trimestres d'une certaine plage */
%macro iteration(debut, fin);
  %global liste_an;
  %let liste_an = ;
  %do i = &debut. %to &fin.;
    %let liste_an = &liste_an.&i.-;
  %end;
  *%let liste_an = %substr(&liste_an., 1, %eval(%length(&liste_an.) - 1));
%mend iteration;
%iteration(debut = 2000, fin = %sysfunc(year(%sysfunc(today()))));
%put &liste_an.;
%let liste_trim = 1 2 3 4;
%let liste_niv = max min;
/* Supposons que nous ayons des noms de fichier suffix�s par AXXXX_TY_NZ, avec X l'ann�e, Y le trimestre et
   Z max ou min. Par exemple, A2010_T2_NMax */
/* Pour obtenir l'ensemble de ces noms de 2010 � cette ann�e */
%macro noms_fichiers(base = temp);
  %global res;
  %let res = ;
  %do j = 1 %to %sysfunc(countw(&liste_an., "-"));
    %let y = %scan(&liste_an., &j., "-"); /* ann�e */
    %do i = 1 %to 4;
      %let t = %scan(&liste_trim, &i.); /* trimestre */
      %do g = 1 %to 2;
        %let n = %scan(&liste_niv., &g.); /* niveau */
		%let res = &res. &base._&y._t&t._n&n.;
	  %end;
	%end;
  %end;
%mend noms_fichiers;
%noms_fichiers(base = base);
%put &res.;


/* On va cr�er une base par ann�e d'entr�e */
proc sql noprint;select year(min(date_entree)), year(max(date_entree)) into :an_min, :an_max from Donnees;quit;
%macro Base_par_mois(debut, fin);
  /* %local impose que an n'est pas de signification hors de la macro */
  %local an;
  /* %global impose que nom_bases peut �tre utilis� en dehors de la macro */
  %global nom_bases;
  /* On initalise la cr�ation de la macri-variable nom_bases */
  %let nom_bases = ;
  /* On it�re entre &debut. et &fin. */
  %do an = &debut. %to &fin.;
    data Entree_&an.;
	  set Donnees;
	  if year(date_entree) = &an.;
	run;
	/* On ajoute � la macro-variable le nom de la base */
	%let nom_bases = &nom_bases. Entree_&an.;
  %end;
%mend Base_par_mois;
%Base_par_mois(debut = &an_min., fin = &an_max.);
%put &nom_bases.;

/* On va d�sormais empiler toutes les bases (concat�nation par colonne) */
/* L'instruction set utilis�e de cette fa�on permet cet empilement */
data Donnees_concatene;
  set &nom_bases.;
run;





/**************************************************************** Fin du programme SAS ****************************************************************/

/* Supprimer toutes les bases de la m�moire vive (la work) => rm(list = ls()) */
proc datasets lib = work nolist kill;run;



/* Quelques points de vigilance en SAS (� ne conna�tre que si on est amen� � modifier le programme SAS, pas utiles sinon) */
/* Double guillemets pour les macro-variables */
%let a = Bonjour;
%put '&a.'; /* Incorrect */
%put "&a."; /* Correct */

/* Macro-variable d�finie avec un statut global avant son appel dans le cadre d'un statut local */
%macro test;%let an = 2022;%mend test;
%test;
/* 1. Erreur car an n'est d�fini que dans le cas d'un environnement local */ 
%put &an.;
/* 2. D�fini auparavant dans un environnement local, elle change de valeur � l'appel de la fonction */
%let an = 2023;
%put Ann�e : &an.;
%test;
%put Ann�e apr�s la macro : &an.;
/* 3. Probl�me corrig�, en imposant la variable � local dans la macro */
%macro test2;
  %local an;
  %let an = 2022;
%mend test2;
%let an = 2023;
%put Ann�e : &an.;
%test2;
%put Ann�e apr�s la macro : &an.;
