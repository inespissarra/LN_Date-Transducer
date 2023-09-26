#!/bin/zsh

mkdir -p compiled images


# ############ Compile source transducers ############
for i in sources/*.txt tests/*.txt; do
	echo "Compiling: $i"
    fstcompile --isymbols=syms.txt --osymbols=syms.txt $i | fstarcsort > compiled/$(basename $i ".txt").fst
done

# ############ CORE OF THE PROJECT  ############

# concatenate the transducers

#  Asked transducers:                                                   Extra:
#   -  mmm2mm.fst                                                         -  day_number.fst
#   -  mix2numerical.fst                                                  -  year_number.fst
#   -  pt2en.fst                                                          -  day_year.fst
#   -  en2pt.fst                                                          -  month_pt2en.fst
#   -  day.fst                                                            -  month_en2pt.fst
#   -  month.fst                                                          -  rm_slash.fst
#   -  year.fst                                                           -  month_noslash.fst
#   -  datenum2text.fst                                                   -  month_day.fst
#   -  mix2text.fst                                                       -  comma.fst
#   -  date2text.fst                                                      -  month_day_comma.fst
#                                                                         -  tmp.fst
#                                                                         -  tmp1.fst


fstconcat compiled/day_number.fst compiled/year_number.fst > compiled/day_year.fst

fstconcat compiled/mmm2mm.fst compiled/day_year.fst > compiled/mix2numerical.fst

fstconcat compiled/month_pt2en.fst compiled/day_year.fst > compiled/pt2en.fst

fstinvert compiled/month_pt2en.fst > compiled/month_en2pt.fst
fstconcat compiled/month_en2pt.fst compiled/day_year.fst > compiled/en2pt.fst

fstconcat compiled/month.fst compiled/rm_slash.fst > compiled/month_no_slash.fst
fstconcat compiled/month_no_slash.fst compiled/day.fst > compiled/month_day.fst
fstconcat compiled/month_day.fst compiled/comma.fst > compiled/month_day_comma.fst
fstconcat compiled/month_day_comma.fst compiled/year.fst > compiled/datenum2text.fst

fstcompose compiled/pt2en.fst compiled/mix2numerical.fst > compiled/tmp.fst
fstunion compiled/tmp.fst compiled/mix2numerical.fst > compiled/tmp1.fst
fstcompose compiled/tmp1.fst compiled/datenum2text.fst > compiled/mix2text.fst

##########################################################################################
#fstcompose compiled/month_pt2en.fst compiled/mmm2mm.fst > compiled/tmp.fst
#fstunion compiled/tmp.fst compiled/mmm2mm.fst > compiled/tmp1.fst
#fstconcat compiled/tmp1.fst compiled/day_year.fst > compiled/tmp2.fst
#fstcompose compiled/tmp2.fst compiled/datenum2text.fst | fstrmepsilon > compiled/mix2text.fst
##########################################################################################

fstunion compiled/mix2text.fst compiled/datenum2text.fst > compiled/date2text.fst

# ############ generate PDFs  ############
echo "Starting to generate PDFs"
for i in compiled/*.fst; do
	echo "Creating image: images/$(basename $i '.fst').pdf"
   fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/$(basename $i '.fst').pdf
done



# ############      3 different ways of testing     ############
# ############ (you can use the one(s) you prefer)  ############

1 - generates files
echo "\n****************************************************************"
echo "Testing date2text (the output is a transducer: fst and pdf)"
echo "****************************************************************"
for w in compiled/t-*.fst; do
    fstcompose $w compiled/date2text.fst | fstshortestpath | fstproject --project_type=output |
                  fstrmepsilon | fsttopsort > compiled/$(basename $w ".fst")-out.fst
done
for i in compiled/t-*-out.fst; do
	echo "Creating image: images/$(basename $i '.fst').pdf"
   fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/$(basename $i '.fst').pdf
done

# #2 - present the output as an acceptor
# #echo "\n***********************************************************"
# #echo "Testing 1 2 3 4 (output is a acceptor)"
# #echo "***********************************************************"
# #trans=n2text.fst
# #echo "\nTesting $trans"
# #for w in "1" "2" "3" "4"; do
# #    echo "\t $w"
# #    ./scripts/word2fst.py $w | fstcompile --isymbols=syms.txt --osymbols=syms.txt | fstarcsort |
# #                     fstcompose - compiled/$trans | fstshortestpath | fstproject --project_type=output |
# #                     fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=syms.txt
# #done


#3 - presents the output with the tokens concatenated (uses a different syms on the output)
fst2word() { awk '{if(NF>=3){printf("%s",$3)}}END{printf("\n")}' }

trans=mix2numerical.fst
echo "\n***********************************************************"
echo "Testing mix2numerical (output is a string  using 'syms-out.txt')"
echo "***********************************************************"
for w in "APR/26/2020" "APR/11/2020"; do
    res=$(./scripts/word2fst.py $w | fstcompile --isymbols=syms.txt --osymbols=syms.txt | fstarcsort |
                       fstcompose - compiled/$trans | fstshortestpath | fstproject --project_type=output |
                       fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./scripts/syms-out.txt | fst2word)
    echo "$w = $res"
done

echo "\nThe end"


#3 - presents the output with the tokens concatenated (uses a different syms on the output)
fst2word() { awk '{if(NF>=3){printf("%s",$3)}}END{printf("\n")}' }

trans=en2pt.fst
echo "\n***********************************************************"
echo "Testing en2pt (output is a string  using 'syms-out.txt')"
echo "***********************************************************"
for w in "APR/26/2020" "APR/11/2020"; do
    res=$(./scripts/word2fst.py $w | fstcompile --isymbols=syms.txt --osymbols=syms.txt | fstarcsort |
                       fstcompose - compiled/$trans | fstshortestpath | fstproject --project_type=output |
                       fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./scripts/syms-out.txt | fst2word)
    echo "$w = $res"
done

echo "\nThe end"


#3 - presents the output with the tokens concatenated (uses a different syms on the output)
fst2word() { awk '{if(NF>=3){printf("%s",$3)}}END{printf("\n")}' }

trans=datenum2text.fst
echo "\n***********************************************************"
echo "Testing datenum2text (output is a string  using 'syms-out.txt')"
echo "***********************************************************"
for w in "04/26/2020" "4/11/2020"; do
    res=$(./scripts/word2fst.py $w | fstcompile --isymbols=syms.txt --osymbols=syms.txt | fstarcsort |
                       fstcompose - compiled/$trans | fstshortestpath | fstproject --project_type=output |
                       fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./scripts/syms-out.txt | fst2word)
    echo "$w = $res"
done

echo "\nThe end"

#3 - presents the output with the tokens concatenated (uses a different syms on the output)
fst2word() { awk '{if(NF>=3){printf("%s",$3)}}END{printf("\n")}' }

trans=mix2text.fst
echo "\n***********************************************************"
echo "Testing mix2text (output is a string  using 'syms-out.txt')"
echo "***********************************************************"
for w in "APR/26/2020" "ABR/11/2020"; do
    res=$(./scripts/word2fst.py $w | fstcompile --isymbols=syms.txt --osymbols=syms.txt | fstarcsort |
                       fstcompose - compiled/$trans | fstshortestpath | fstproject --project_type=output |
                       fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./scripts/syms-out.txt | fst2word)
    echo "$w = $res"
done

echo "\nThe end"


#3 - presents the output with the tokens concatenated (uses a different syms on the output)
fst2word() { awk '{if(NF>=3){printf("%s",$3)}}END{printf("\n")}' }

trans=date2text.fst
echo "\n***********************************************************"
echo "Testing date2text (output is a string  using 'syms-out.txt')"
echo "***********************************************************"
for w in "APR/26/2020" "ABR/11/2020" "04/26/2020" "4/11/2020"; do
    res=$(./scripts/word2fst.py $w | fstcompile --isymbols=syms.txt --osymbols=syms.txt | fstarcsort |
                       fstcompose - compiled/$trans | fstshortestpath | fstproject --project_type=output |
                       fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./scripts/syms-out.txt | fst2word)
    echo "$w = $res"
done

echo "\nThe end"


#3 - presents the output with the tokens concatenated (uses a different syms on the output)
fst2word() { awk '{if(NF>=3){printf("%s",$3)}}END{printf("\n")}' }

trans=date2text.fst
echo "\n***********************************************************"
echo "Testing date2text (output is a string  using 'syms-out.txt')"
echo "***********************************************************"
for w in "9/09/2001" "01/3/2011" "02/24/2022" "10/01/2099" "12/22/2043" "OCT/30/2025" "DEZ/13/2069" "FEV/25/2071" "MAR/21/2060"; do
    res=$(./scripts/word2fst.py $w | fstcompile --isymbols=syms.txt --osymbols=syms.txt | fstarcsort |
                       fstcompose - compiled/$trans | fstshortestpath | fstproject --project_type=output |
                       fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./scripts/syms-out.txt | fst2word)
    echo "$w = $res"
done

echo "\nThe end"