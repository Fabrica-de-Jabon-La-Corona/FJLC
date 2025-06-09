
clear GS_IT_QM.

* read quality message
read table
           IS_DLV_DELNOTE-IT_QM into GS_IT_QM


           with key DELIV_NUMB = GS_IT_GEN-DELIV_NUMB
                    ITM_NUMBER = GS_IT_GEN-ITM_NUMBER binary search.

























