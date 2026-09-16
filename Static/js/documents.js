            function getSelectedCategoryInfo(selectElem) {
                if (!selectElem) return { val: "All", text: "Contract Staff", cleanName: "Contract Staff" };
                const val = selectElem.value || "All";
                const selectedOption = selectElem.options && selectElem.selectedIndex >= 0 ? selectElem.options[selectElem.selectedIndex] : null;
                let text = selectedOption ? (selectedOption.text || "") : "Contract Staff";
                
                if (val === "All" || text === "All Categories" || !val) {
                    return { val: "All", text: "Contract Staff", cleanName: "Contract Staff" };
                }

                // Extract tier/category name if format is "MainCategory > Tier (#Role)" or "Skilled"
                let cleanName = text;
                if (cleanName.includes(" > ")) {
                    const parts = cleanName.split(" > ");
                    cleanName = parts[parts.length - 1].trim();
                }
                cleanName = cleanName.replace(/\s*\(\s*#.*\)/, "").trim();

                return { val: val, text: text, cleanName: cleanName || text };
            }

            function getGlobalContext(docType) {
                // Collect year, month, category, division
                let year = "2026";
                let monthIndex = 4; // May
                let catInfo = { val: "All", text: "Contract Staff", cleanName: "Contract Staff" };
                let division = "[Division]";
                
                // Check active workspace or default based on docType
                let activeDoc = docType;
                if (!activeDoc) {
                    if (document.getElementById("attendanceCertWorkspace") && document.getElementById("attendanceCertWorkspace").style.display !== "none") activeDoc = "attendance";
                    else if (document.getElementById("satisfactoryCertWorkspace") && document.getElementById("satisfactoryCertWorkspace").style.display !== "none") activeDoc = "satisfactory";
                    else if (document.getElementById("coveringLetterWorkspace") && document.getElementById("coveringLetterWorkspace").style.display !== "none") activeDoc = "covering";
                    else if (document.getElementById("wagesCalcWorkspace") && document.getElementById("wagesCalcWorkspace").style.display !== "none") activeDoc = "wages";
                    else if (document.getElementById("attendanceReportWorkspace") && document.getElementById("attendanceReportWorkspace").style.display !== "none") activeDoc = "report";
                }

                if (activeDoc === "attendance") {
                    year = document.getElementById("year")?.value || "2026";
                    monthIndex = parseInt(document.getElementById("month")?.value || "4");
                    catInfo = getSelectedCategoryInfo(document.getElementById("category"));
                } else if (activeDoc === "satisfactory") {
                    year = document.getElementById("satYear")?.value || "2026";
                    monthIndex = parseInt(document.getElementById("satMonth")?.value || "4");
                    catInfo = getSelectedCategoryInfo(document.getElementById("satCategory"));
                } else if (activeDoc === "covering") {
                    year = document.getElementById("covYear")?.value || "2026";
                    monthIndex = parseInt(document.getElementById("covMonth")?.value || "4");
                    catInfo = getSelectedCategoryInfo(document.getElementById("covCategory"));
                    division = document.getElementById("covDivision")?.value || "[Division]";
                } else if (activeDoc === "wages") {
                    year = document.getElementById("wagesYear")?.value || "2026";
                    monthIndex = parseInt(document.getElementById("wagesMonth")?.value || "4");
                    catInfo = getSelectedCategoryInfo(document.getElementById("wagesCategory"));
                } else if (activeDoc === "report") {
                    year = document.getElementById("repYear")?.value || "2026";
                    monthIndex = parseInt(document.getElementById("repMonth")?.value || "4");
                    catInfo = getSelectedCategoryInfo(document.getElementById("repCategory"));
                }

                const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
                const monthName = months[monthIndex];
                const daysInMonth = new Date(parseInt(year), monthIndex + 1, 0).getDate();

                // Ordinal suffix helper
                const getSuffix = (d) => {
                    if (d > 3 && d < 21) return 'th';
                    switch (d % 10) {
                        case 1:  return "st";
                        case 2:  return "nd";
                        case 3:  return "rd";
                        default: return "th";
                    }
                };

                // Current Date values (Today)
                const now = new Date();
                const nowDay = now.getDate();
                const nowMonthIdx = now.getMonth();
                const nowYear = now.getFullYear();
                const nowPadDay = String(nowDay).padStart(2, '0');
                const nowPadMonth = String(nowMonthIdx + 1).padStart(2, '0');
                const nowMonthName = months[nowMonthIdx];
                const nowShortMonth = nowMonthName.substring(0, 3);

                const currentDate = `${nowPadDay}-${nowShortMonth}-${nowYear}`;
                const currentDateShort = `${nowPadDay}-${nowPadMonth}-${nowYear}`;
                const currentDateSlash = `${nowPadDay}/${nowPadMonth}/${nowYear}`;
                const currentDateSpace = `${nowPadDay} ${nowMonthName} ${nowYear}`;
                const currentDateLong = `${nowPadDay}${getSuffix(nowDay)} ${nowMonthName} ${nowYear}`;

                // Formatted dates
                const shortStart = `01-${monthName.substring(0, 3)}-${year}`;
                const shortEnd = `${daysInMonth}-${monthName.substring(0, 3)}-${year}`;
                
                const spaceStart = `01 ${monthName} ${year}`;
                const spaceEnd = `${daysInMonth} ${monthName} ${year}`;
                
                const longStart = `01st ${monthName} ${year}`;
                const longEnd = `${daysInMonth}${getSuffix(daysInMonth)} ${monthName} ${year}`;

                // Context-sensitive values
                let defaultStart = shortStart;
                let defaultEnd = shortEnd;
                if (docType === "satisfactory") {
                    defaultStart = spaceStart;
                    defaultEnd = spaceEnd;
                } else if (docType === "covering") {
                    defaultStart = longStart;
                    defaultEnd = longEnd;
                } else if (docType === "wages") {
                    defaultStart = spaceStart;
                    defaultEnd = spaceEnd;
                }

                // Resolve contract object based on activeDoc
                let contractObj = null;
                if (activeDoc === "report") {
                    const contractSel = document.getElementById("repContract");
                    const selectedId = contractSel && contractSel.value ? parseInt(contractSel.value) : null;
                    if (selectedId && typeof reportContractsList !== "undefined") {
                        contractObj = reportContractsList.find(c => c.Id === selectedId);
                    }
                } else if (activeDoc === "covering") {
                    const contractSel = document.getElementById("covContract");
                    const selectedId = contractSel && contractSel.value ? parseInt(contractSel.value) : null;
                    if (selectedId && typeof covContractsList !== "undefined") {
                        contractObj = covContractsList.find(c => c.Id === selectedId);
                    }
                } else if (activeDoc === "satisfactory") {
                    const contractSel = document.getElementById("satContract");
                    const selectedId = contractSel && contractSel.value ? parseInt(contractSel.value) : null;
                    if (selectedId && typeof satContractsList !== "undefined") {
                        contractObj = satContractsList.find(c => c.Id === selectedId);
                    }
                } else if (activeDoc === "wages") {
                    const contractSel = document.getElementById("wagesContract");
                    const selectedId = contractSel && contractSel.value ? parseInt(contractSel.value) : null;
                    if (selectedId && typeof wagesContractsList !== "undefined") {
                        contractObj = wagesContractsList.find(c => c.Id === selectedId);
                    }
                } else {
                    const contractSel = document.getElementById("contract");
                    const selectedId = contractSel && contractSel.value ? parseInt(contractSel.value) : null;
                    if (selectedId && typeof contractsList !== "undefined") {
                        contractObj = contractsList.find(c => c.Id === selectedId);
                    }
                }

                // Gather input values with fallback values
                const vendorName = (activeDoc === "report") ? (contractObj ? (contractObj.VendorName || "") : "VISHAL MANPOWER & SECURITY CONSULTANTS") :
                                   (contractObj && contractObj.VendorName ? contractObj.VendorName :
                                   (document.getElementById("vendorName")?.value || 
                                   document.getElementById("satVendorNameInput")?.value || 
                                   document.getElementById("wagesVendorNameInput")?.value || 
                                   "[Vendor Name]"));
                                   
                const vendorAddress = (activeDoc === "report") ? (contractObj ? (contractObj.VendorAddress || "") : "Mangalore") :
                                      (contractObj && contractObj.VendorAddress ? contractObj.VendorAddress :
                                      (document.getElementById("vendorAddress")?.value || 
                                      document.getElementById("satVendorAddressInput")?.value || 
                                      document.getElementById("wagesVendorAddressInput")?.value || 
                                      "[Vendor Address]"));
                                      
                const contractNo = (activeDoc === "report") ? (contractObj ? (contractObj.GemId || "") : "GEMC-511687761569464") :
                                   (contractObj && contractObj.GemId ? contractObj.GemId :
                                   (document.getElementById("gemContractNo")?.value || 
                                   document.getElementById("satGemNoInput")?.value || 
                                   document.getElementById("wagesContractNoInput")?.value || 
                                   "[GeM Contract No]"));
                                   
                const contractDate = (activeDoc === "report") ? (contractObj ? (contractObj.StartDate || "") : "[Contract Date]") :
                                     (contractObj && contractObj.StartDate ? contractObj.StartDate :
                                     (document.getElementById("gemContractDate")?.value || 
                                     document.getElementById("satContractDateInput")?.value || 
                                     document.getElementById("wagesContractDateInput")?.value || 
                                     "[Contract Date]"));
                                     
                const datedOn = (activeDoc === "report") ? (document.getElementById("repDatedOnInput")?.value || "[Dated On]") :
                                (contractObj && contractObj.VendorDatedOn ? contractObj.VendorDatedOn :
                                (document.getElementById("certDatedOnInput")?.value || 
                                document.getElementById("satDatedOnInput")?.value || 
                                document.getElementById("wagesDatedOnInput")?.value || 
                                "[Dated On]"));

                const services = document.getElementById("satServicesInput")?.value || "[Services]";
                const duration = document.getElementById("satDurationInput")?.value || "[Duration]";
                const wefDate = document.getElementById("satWefInput")?.value || "[w.e.f. Date]";
                
                // Signatory
                const signatory = document.getElementById("satSignatoryInput")?.value || 
                                  document.getElementById("covSignatoryInput")?.value || 
                                  "[Signatory Name]";
                const designation = document.getElementById("satDesignationInput")?.value || 
                                    document.getElementById("covDesignationInput")?.value || 
                                    "[Signatory Designation]";

                // EmpCount
                let empCount = document.getElementById("satEmpCountInput")?.value || "0";
                if (empCount === "0" && typeof wagesEmployeesData !== "undefined" && wagesEmployeesData.length > 0) {
                    empCount = wagesEmployeesData.length.toString();
                } else if (empCount === "0" && typeof satEmployeesData !== "undefined" && satEmployeesData.length > 0) {
                    empCount = satEmployeesData.length.toString();
                } else if (empCount === "0" && typeof employeesData !== "undefined" && employeesData.length > 0) {
                    empCount = employeesData.length.toString();
                }

                const catLabel = (catInfo && catInfo.val !== "All") ? (catInfo.cleanName || catInfo.text || "Contract Staff") : "Contract Staff";
                const dictLookup = (typeof wagesCategoryDescriptions !== "undefined" && wagesCategoryDescriptions && catInfo) 
                    ? (wagesCategoryDescriptions[catInfo.cleanName] || wagesCategoryDescriptions[catInfo.val]) 
                    : null;
                const savedDesc = (catInfo && catInfo.val !== "All") 
                    ? (dictLookup || catInfo.cleanName || catInfo.text || "Contract Staff") 
                    : "Contract Staff";
                const categoryDesc = (activeDoc === "wages" && document.getElementById("wagesCategoryDescInput")?.value) 
                    ? document.getElementById("wagesCategoryDescInput").value 
                    : savedDesc;
                
                // Wages specific
                const period = document.getElementById("wagesPeriodInput")?.value || `${shortStart} to ${shortEnd}`;
                const extraCode = document.getElementById("wagesExtraCodeInput")?.value || "";

                // Working days excluding Sundays
                let workingDaysExcludingSundays = 0;
                for (let d = 1; d <= daysInMonth; d++) {
                    const dayOfWeek = new Date(parseInt(year), monthIndex, d).getDay();
                    if (dayOfWeek !== 0) workingDaysExcludingSundays++;
                }

                // Global Adjustment for wage calculation header
                let globalAdj = 0;
                if (typeof wagesMetadata !== 'undefined' && wagesMetadata && wagesMetadata.GlobalAdjustment !== undefined) {
                    globalAdj = parseFloat(wagesMetadata.GlobalAdjustment) || 0;
                }
                const totalWorkingDays = workingDaysExcludingSundays + globalAdj;

                const contractPeriod = (activeDoc === "report") ? (contractObj ? (contractObj.DisplayName || "") : "") : "";

                return {
                    "Category": catLabel,
                    "CategoryUpper": catLabel.toUpperCase(),
                    "CategoryDesc": categoryDesc,
                    "CategoryDescUpper": categoryDesc.toUpperCase(),
                    "VendorName": vendorName,
                    "VendorNameUpper": vendorName.toUpperCase(),
                    "VendorAddress": vendorAddress,
                    "VendorAddressUpper": vendorAddress.toUpperCase(),
                    "ContractNo": contractNo,
                    "ContractDate": contractDate,
                    "DatedOn": datedOn,
                    "StartDate": defaultStart,
                    "EndDate": defaultEnd,
                    "StartDateShort": shortStart,
                    "EndDateShort": shortEnd,
                    "StartDateSpace": spaceStart,
                    "EndDateSpace": spaceEnd,
                    "StartDateLong": longStart,
                    "EndDateLong": longEnd,
                    "PaymentStart": defaultStart,
                    "PaymentEnd": defaultEnd,
                    "Date": currentDate,
                    "DateUpper": currentDate.toUpperCase(),
                    "DateShort": currentDateShort,
                    "DateSlash": currentDateSlash,
                    "DateSpace": currentDateSpace,
                    "DateLong": currentDateLong,
                    "Today": currentDate,
                    "TodayUpper": currentDate.toUpperCase(),
                    "CurrentDate": currentDate,
                    "Day": nowPadDay,
                    "DayNum": String(nowDay),
                    "Year": year,
                    "Month": monthName,
                    "MonthUpper": monthName.toUpperCase(),
                    "MonthLower": monthName.toLowerCase(),
                    "MonthShort": monthName.substring(0, 3),
                    "MonthShortUpper": monthName.substring(0, 3).toUpperCase(),
                    "Division": division,
                    "DivisionUpper": division.toUpperCase(),
                    "Services": services,
                    "ServicesUpper": services.toUpperCase(),
                    "Duration": duration,
                    "WefDate": wefDate,
                    "EmpCount": empCount,
                    "PeopleCount": empCount,
                    "WorkingDays": totalWorkingDays,
                    "Period": period,
                    "ExtraCode": extraCode,
                    "ContractPeriod": contractPeriod,
                    // Metadata for arithmetic and offset placeholder evaluation
                    "_rawYear": parseInt(year, 10) || 2026,
                    "_rawMonthIndex": monthIndex,
                    "_rawEmpCount": parseInt(empCount, 10) || 0,
                    "_rawWorkingDays": totalWorkingDays,
                    "_docType": activeDoc || docType
                };
            }

            // Universal Templating Engine with Arithmetic Offsets (+/-), Modifiers (:upper, :lower, :title, :short), and Auto-Casing
            function replacePlaceholders(templateText, docType) {
                if (!templateText) return "";
                const ctx = getGlobalContext(docType);
                
                // Build a normalized case-insensitive map of keys with aliases
                const lookup = {};
                for (const [k, v] of Object.entries(ctx)) {
                    lookup[k.toLowerCase()] = v;
                    lookup[k.toLowerCase().replace(/[\s_-]+/g, '')] = v;
                }
                // Convenient aliases
                lookup["currentmonth"] = ctx.Month;
                lookup["currentyear"] = ctx.Year;
                lookup["currentempcount"] = ctx.EmpCount;
                lookup["currentworkingdays"] = ctx.WorkingDays;
                lookup["currentdate"] = ctx.Date;
                lookup["today"] = ctx.Date;
                lookup["date"] = ctx.Date;

                const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
                const getSuffix = (d) => {
                    if (d > 3 && d < 21) return 'th';
                    switch (d % 10) {
                        case 1:  return "st";
                        case 2:  return "nd";
                        case 3:  return "rd";
                        default: return "th";
                    }
                };

                // Match {PlaceholderName}, {PlaceholderName-1}, {PlaceholderName - 1}, { month-1 }, {current month - 1}, {PlaceholderName-1:upper}, {PlaceholderName:-1}
                return templateText.replace(/\{\s*([a-zA-Z0-9_\s]+?)(?:\s*([+-])\s*(\d+))?(?::([^}]+))?\s*\}/g, function(match, rawKey, sign, offsetDigits, rawModifiers) {
                    const cleanRawKey = (rawKey || "").trim();
                    let normKey = cleanRawKey.toLowerCase().replace(/[\s_-]+/g, '');
                    if (normKey === 'currentmonth') normKey = 'month';
                    if (normKey === 'currentyear') normKey = 'year';
                    if (normKey === 'currentempcount') normKey = 'empcount';
                    if (normKey === 'currentworkingdays') normKey = 'workingdays';
                    if (normKey === 'currentdate' || normKey === 'today') normKey = 'date';

                    // Parse math offset (+N or -N)
                    let offset = 0;
                    if (sign && offsetDigits) {
                        offset = parseInt(sign + offsetDigits, 10);
                    }

                    // Parse modifiers and check if colon-based offset was provided (e.g. {Month:-1})
                    const remainingMods = [];
                    if (rawModifiers) {
                        const tokens = rawModifiers.split(':').map(t => t.trim());
                        for (const t of tokens) {
                            if (/^[+-]?\d+$/.test(t)) {
                                offset = parseInt(t, 10);
                            } else if (t) {
                                remainingMods.push(t.toLowerCase());
                            }
                        }
                    }

                    // Check if key is known
                    const dateKeys = ['startdate', 'enddate', 'startdateshort', 'enddateshort', 'startdatespace', 'enddatespace', 'startdatelong', 'enddatelong', 'paymentstart', 'paymentend', 'period'];
                    const todayDateFields = ['date', 'dateupper', 'dateshort', 'dateslash', 'datespace', 'datelong', 'day', 'daynum', 'today', 'currentdate'];
                    const isKnownKey = (normKey in lookup) || dateKeys.includes(normKey) || todayDateFields.includes(normKey);
                    if (!isKnownKey) {
                        return match; // Unknown placeholder, leave as is
                    }

                    let val = "";

                    if (offset !== 0) {
                        // 0. Date with arithmetic day offset (e.g. {Date-1}, {Date+1}, {Day-1}, {DateShort-1})
                        if (todayDateFields.includes(normKey)) {
                            const n = new Date();
                            const target = new Date(n.getFullYear(), n.getMonth(), n.getDate() + offset);
                            const tDay = target.getDate();
                            const tPadDay = String(tDay).padStart(2, '0');
                            const tPadMonth = String(target.getMonth() + 1).padStart(2, '0');
                            const tMonthName = months[target.getMonth()];
                            const tShortMonth = tMonthName.substring(0, 3);
                            const tYear = target.getFullYear();

                            if (normKey === 'date' || normKey === 'today' || normKey === 'currentdate') val = `${tPadDay}-${tShortMonth}-${tYear}`;
                            else if (normKey === 'dateupper') val = `${tPadDay}-${tShortMonth.toUpperCase()}-${tYear}`;
                            else if (normKey === 'dateshort') val = `${tPadDay}-${tPadMonth}-${tYear}`;
                            else if (normKey === 'dateslash') val = `${tPadDay}/${tPadMonth}/${tYear}`;
                            else if (normKey === 'datespace') val = `${tPadDay} ${tMonthName} ${tYear}`;
                            else if (normKey === 'datelong') val = `${tPadDay}${getSuffix(tDay)} ${tMonthName} ${tYear}`;
                            else if (normKey === 'day') val = tPadDay;
                            else if (normKey === 'daynum') val = String(tDay);
                        }
                        // 1. Month with arithmetic offset (e.g. {Month-1}, {Month+1}, {MonthShort-1}, {current month - 1})
                        else if (normKey === 'month' || normKey === 'monthupper' || normKey === 'monthlower' || normKey === 'monthshort' || normKey === 'monthshortupper') {
                            const targetDate = new Date(ctx._rawYear, ctx._rawMonthIndex + offset, 1);
                            const tMonthName = months[targetDate.getMonth()];
                            if (normKey === 'month') val = tMonthName;
                            else if (normKey === 'monthupper') val = tMonthName.toUpperCase();
                            else if (normKey === 'monthlower') val = tMonthName.toLowerCase();
                            else if (normKey === 'monthshort') val = tMonthName.substring(0, 3);
                            else if (normKey === 'monthshortupper') val = tMonthName.substring(0, 3).toUpperCase();
                        }
                        // 2. Year with arithmetic offset (e.g. {Year-1}, {Year+1})
                        else if (normKey === 'year') {
                            val = String(ctx._rawYear + offset);
                        }
                        // 3. Employee Count with arithmetic offset (e.g. {EmpCount-1}, {PeopleCount+1})
                        else if (normKey === 'empcount' || normKey === 'peoplecount') {
                            val = String(Math.max(0, ctx._rawEmpCount + offset));
                        }
                        // 4. Working Days with arithmetic offset (e.g. {WorkingDays-1})
                        else if (normKey === 'workingdays') {
                            val = String(Math.max(0, Math.round(ctx._rawWorkingDays + offset)));
                        }
                        // 5. Date fields with arithmetic month offset (e.g. {StartDate-1}, {EndDate-1}, {Period-1})
                        else if (dateKeys.includes(normKey)) {
                            const targetDate = new Date(ctx._rawYear, ctx._rawMonthIndex + offset, 1);
                            const tYear = targetDate.getFullYear();
                            const tMonthIdx = targetDate.getMonth();
                            const tMonthName = months[tMonthIdx];
                            const tDaysInMonth = new Date(tYear, tMonthIdx + 1, 0).getDate();

                            const tShortStart = `01-${tMonthName.substring(0, 3)}-${tYear}`;
                            const tShortEnd = `${tDaysInMonth}-${tMonthName.substring(0, 3)}-${tYear}`;
                            const tSpaceStart = `01 ${tMonthName} ${tYear}`;
                            const tSpaceEnd = `${tDaysInMonth} ${tMonthName} ${tYear}`;
                            const tLongStart = `01st ${tMonthName} ${tYear}`;
                            const tLongEnd = `${tDaysInMonth}${getSuffix(tDaysInMonth)} ${tMonthName} ${tYear}`;

                            let tDefaultStart = tShortStart;
                            let tDefaultEnd = tShortEnd;
                            const activeDocType = ctx._docType || docType;
                            if (activeDocType === "satisfactory" || activeDocType === "wages") {
                                tDefaultStart = tSpaceStart;
                                tDefaultEnd = tSpaceEnd;
                            } else if (activeDocType === "covering") {
                                tDefaultStart = tLongStart;
                                tDefaultEnd = tLongEnd;
                            }

                            if (normKey === 'startdate' || normKey === 'paymentstart') val = tDefaultStart;
                            else if (normKey === 'enddate' || normKey === 'paymentend') val = tDefaultEnd;
                            else if (normKey === 'startdateshort') val = tShortStart;
                            else if (normKey === 'enddateshort') val = tShortEnd;
                            else if (normKey === 'startdatespace') val = tSpaceStart;
                            else if (normKey === 'enddatespace') val = tSpaceEnd;
                            else if (normKey === 'startdatelong') val = tLongStart;
                            else if (normKey === 'enddatelong') val = tLongEnd;
                            else if (normKey === 'period') val = `${tShortStart} to ${tShortEnd}`;
                        }
                        // 6. Any other numeric fields in context
                        else if (normKey in lookup && /^-?\d+$/.test(String(lookup[normKey]).trim())) {
                            val = String(parseInt(String(lookup[normKey]).trim(), 10) + offset);
                        }
                        // 7. Non-numeric field fallback
                        else if (normKey in lookup) {
                            val = lookup[normKey] !== null && lookup[normKey] !== undefined ? String(lookup[normKey]) : "";
                        }
                    } else {
                        // Standard resolution (offset === 0)
                        val = lookup[normKey] !== null && lookup[normKey] !== undefined ? String(lookup[normKey]) : "";
                    }

                    // Apply formatting modifiers (e.g. :upper, :lower, :title, :short)
                    if (remainingMods.length > 0) {
                        for (const mod of remainingMods) {
                            if (mod === 'upper' || mod === 'caps' || mod === 'uppercase') {
                                val = val.toUpperCase();
                            } else if (mod === 'lower' || mod === 'lowercase') {
                                val = val.toLowerCase();
                            } else if (mod === 'title' || mod === 'capitalize' || mod === 'capital') {
                                val = val.replace(/\b\w/g, c => c.toUpperCase());
                            } else if (mod === 'short') {
                                if (normKey.includes('month') && val.length > 3) {
                                    val = val.substring(0, 3);
                                }
                            }
                        }
                        return val;
                    }

                    // Auto-case detection if the placeholder itself was written in ALL UPPERCASE (e.g. {MONTH-1}, {CATEGORY}, {YEAR-1})
                    if (cleanRawKey === cleanRawKey.toUpperCase() && cleanRawKey.length > 1 && /[A-Z]/.test(cleanRawKey)) {
                        return val.toUpperCase();
                    }

                    return val;
                });
            }

            let categories = [];
            let contractsList = [];
            let employeesData = [];
            let tplDesc1 = "This is certify that DEO ({Category}) under GeM Contract No: {ContractNo}, dated: {ContractDate}";
            let tplDesc2 = "M/s. {VendorName}, {VendorAddress} worked as following, for the period from {StartDate} to {EndDate}";
            let tplSatDesc1 = "This is to certify that M/s. <b>{VendorName}</b>, {VendorAddress} is engaged as an Industry Partner in our Establishment to provide Services towards <b>{Services}</b> for a period of {Duration} w.e.f. {WefDate} against GeM Contract No. <b>{ContractNo}</b> dated {ContractDate}.";
            let tplSatDesc2 = "The Industry Partner provided <b>{EmpCount}</b> Contract Employees and found working satisfactorily.";
            let tplSatDesc3 = "The service provided by the Industry Partner from {StartDate} to {EndDate} is found satisfactory.";

            let tplCovPhone = "2312";
            let tplCovRefNo = "49805/HRD/HM/{Year}";
            let tplCovSubject = "HIRING OF MANPOWER SERVICES";
            let tplCovBody = "The copies of the Attendance report along with the wage calculation for {Category} category Contract Employees from M/s. {VendorName}, {VendorAddress} for the period of {StartDate} to {EndDate} is enclosed. This is for purpose of their payment processing please.";
            let tplCovSignatory = "Usha Nandini AA";
            let tplCovDesignation = "TO C";
            let tplCovAuthority = "For GD, {Division}";
            let tplCovRecipient = "To,\nD-FMM/Purchase";
            let tplWagesHdrContract = "Contract No. <b>{ContractNo}</b> Dt. <b>{ContractDate}</b> {ExtraCode}";
            let tplWagesHdrCategory = "Manpower Outstanding Services - Data Entry Operators({CategoryDesc}) - {PeopleCount} No.s";
            let tplWagesHdrPeriod = "Contract Period <b>{Period}</b>";
            let tplWagesHdrVendor = "M/s {VendorName}, {VendorAddress}";
            let tplWagesHdrPayment = "Payment for the period <b>{PaymentStart}</b> to <b>{PaymentEnd}</b> - <b>{WorkingDays} days</b>";

            let tplRepTpl1H1 = "ATTENDANCE REPORT OF CONTRACTOR WORKERS FOR THE MONTH OF {Month:upper} {Year}";
            let tplRepTpl1H2 = "Name of Vendor: M/s. {VendorName} | GeM Contract No: {ContractNo}";
            let tplRepTpl2H1 = "MONTHLY STATEMENT OF CONTRACTOR WORKERS ATTENDANCE";
            let tplRepTpl2H2 = "Category: {Category} | Contract Period: {ContractPeriod} | GeM Contract: {ContractNo}";

            let wagesCategoryDescriptions = {
                "Skilled": "Data Entry Operators(Skilled)",
                "Semi-Skilled": "Staff",
                "Unskilled": "attender"
            };
            let pocRepCategoryDescriptions = {
                "Skilled": "DEO",
                "Semi-Skilled": "Office Assistant",
                "Unskilled": "Attender"
            };
            let templateDbCategories = [];
            let covContractsList = [];

            // Global Toast Notification System
            function showToast(msg, type = 'info') {
                let container = document.getElementById("toast-container");
                if (!container) {
                    container = document.createElement("div");
                    container.id = "toast-container";
                    document.body.appendChild(container);
                }

                const toast = document.createElement("div");
                toast.className = `modern-toast toast-${type}`;

                let iconClass = "fas fa-info-circle";
                if (type === "success") iconClass = "fas fa-check-circle";
                else if (type === "warning") iconClass = "fas fa-exclamation-triangle";
                else if (type === "error") iconClass = "fas fa-times-circle";

                toast.innerHTML = `
                <div class="toast-icon"><i class="${iconClass}"></i></div>
                <div style="flex-grow: 1; padding-right: 8px;">${msg}</div>
                <button type="button" class="toast-close-btn" onclick="this.parentElement.classList.remove('toast-show'); setTimeout(() => this.parentElement.remove(), 400);">&times;</button>
            `;

                container.appendChild(toast);

                // Trigger reflow
                toast.offsetHeight;
                toast.classList.add("toast-show");

                // Auto dismiss
                setTimeout(() => {
                    if (toast.parentElement) {
                        toast.classList.remove("toast-show");
                        toast.classList.add("toast-hide");
                        setTimeout(() => { toast.remove(); }, 400);
                    }
                }, 4000);
            }

            function togglePlaceholdersDrawer() {
                const drawer = document.getElementById("placeholdersDrawer");
                const overlay = document.getElementById("drawerOverlay");
                if (drawer && overlay) {
                    if (drawer.classList.contains("open")) {
                        closePlaceholdersDrawer();
                    } else {
                        drawer.classList.add("open");
                        overlay.style.display = "block";
                    }
                }
            }

            function closePlaceholdersDrawer() {
                const drawer = document.getElementById("placeholdersDrawer");
                const overlay = document.getElementById("drawerOverlay");
                if (drawer && overlay) {
                    drawer.classList.remove("open");
                    overlay.style.display = "none";
                }
            }

            function selectDocument(docType, skipFilterChange) {
                document.getElementById('documentHubView').style.display = 'none';

                // Close drawer when switching workspace
                closePlaceholdersDrawer();
                closeWagesAltDrawer();

                if (docType === 'attendance-cert') {
                    document.getElementById('attendanceCertWorkspace').style.display = 'block';
                    document.getElementById('satisfactoryCertWorkspace').style.display = 'none';
                    document.getElementById('coveringLetterWorkspace').style.display = 'none';
                    document.getElementById('wagesCalcWorkspace').style.display = 'none';
                    document.getElementById('templateSettingsWorkspace').style.display = 'none';
                    document.getElementById('pageMainHeader').textContent = 'Attendance Certificate Generator';
                } else if (docType === 'satisfactory-cert') {
                    document.getElementById('attendanceCertWorkspace').style.display = 'none';
                    document.getElementById('satisfactoryCertWorkspace').style.display = 'block';
                    document.getElementById('coveringLetterWorkspace').style.display = 'none';
                    document.getElementById('wagesCalcWorkspace').style.display = 'none';
                    document.getElementById('templateSettingsWorkspace').style.display = 'none';
                    document.getElementById('pageMainHeader').textContent = 'Satisfactory Certificate Generator';
                    populateSatSelectors();
                } else if (docType === 'covering-letter') {
                    document.getElementById('attendanceCertWorkspace').style.display = 'none';
                    document.getElementById('satisfactoryCertWorkspace').style.display = 'none';
                    document.getElementById('coveringLetterWorkspace').style.display = 'block';
                    document.getElementById('wagesCalcWorkspace').style.display = 'none';
                    document.getElementById('templateSettingsWorkspace').style.display = 'none';
                    document.getElementById('pageMainHeader').textContent = 'Covering Letter Generator';
                    populateCovSelectors();
                } else if (docType === 'wages-calc') {
                    document.getElementById('attendanceCertWorkspace').style.display = 'none';
                    document.getElementById('satisfactoryCertWorkspace').style.display = 'none';
                    document.getElementById('coveringLetterWorkspace').style.display = 'none';
                    document.getElementById('wagesCalcWorkspace').style.display = 'block';
                    document.getElementById('templateSettingsWorkspace').style.display = 'none';
                    document.getElementById('pageMainHeader').textContent = 'Wages Calculation Generator';
                    populateWagesSelectors(skipFilterChange);
                } else if (docType === 'attendance-report') {
                    document.getElementById('attendanceCertWorkspace').style.display = 'none';
                    document.getElementById('satisfactoryCertWorkspace').style.display = 'none';
                    document.getElementById('coveringLetterWorkspace').style.display = 'none';
                    document.getElementById('wagesCalcWorkspace').style.display = 'none';
                    document.getElementById('attendanceReportWorkspace').style.display = 'block';
                    document.getElementById('templateSettingsWorkspace').style.display = 'none';
                    document.getElementById('pageMainHeader').textContent = 'Attendance Report Generator';
                    populateReportSelectors();
                } else if (docType === 'template-settings') {
                    document.getElementById('attendanceCertWorkspace').style.display = 'none';
                    document.getElementById('satisfactoryCertWorkspace').style.display = 'none';
                    document.getElementById('coveringLetterWorkspace').style.display = 'none';
                    document.getElementById('wagesCalcWorkspace').style.display = 'none';
                    document.getElementById('attendanceReportWorkspace').style.display = 'none';
                    document.getElementById('templateSettingsWorkspace').style.display = 'block';
                    document.getElementById('pageMainHeader').textContent = 'Global Template Settings';
                    if (typeof onWagesTplCategoryChange === 'function') {
                        onWagesTplCategoryChange();
                    }
                    if (typeof onPocRepCategoryChange === 'function') {
                        onPocRepCategoryChange();
                    }
                }
            }

            function goBackToHub() {
                document.getElementById('documentHubView').style.display = 'block';
                document.getElementById('attendanceCertWorkspace').style.display = 'none';
                document.getElementById('satisfactoryCertWorkspace').style.display = 'none';
                document.getElementById('coveringLetterWorkspace').style.display = 'none';
                document.getElementById('wagesCalcWorkspace').style.display = 'none';
                document.getElementById('attendanceReportWorkspace').style.display = 'none';
                document.getElementById('templateSettingsWorkspace').style.display = 'none';
                document.getElementById('pageMainHeader').textContent = 'Document Hub';

                // Close drawer when going back
                closePlaceholdersDrawer();
                closeWagesAltDrawer();
            }

            function switchTemplateTab(evt, tabId) {
                const contents = document.querySelectorAll('#templateSettingsWorkspace .tab-content');
                contents.forEach(el => el.style.display = 'none');

                const btns = document.querySelectorAll('#templateSettingsWorkspace .tab-btn');
                btns.forEach(btn => {
                    btn.classList.remove('active');
                    btn.style.color = '#64748b';
                    btn.style.borderBottom = 'none';
                    btn.style.fontWeight = '600';
                });

                document.getElementById(tabId).style.display = 'block';
                evt.currentTarget.classList.add('active');
                evt.currentTarget.style.color = '#4f46e5';
                evt.currentTarget.style.borderBottom = '2px solid #4f46e5';
                evt.currentTarget.style.fontWeight = '700';

                if (tabId === 'tab-wages') {
                    onWagesTplCategoryChange();
                } else if (tabId === 'tab-poc-report') {
                    onPocRepCategoryChange();
                }
            }

            function loadDatabaseCategoriesForTemplates() {
                return fetch('Documents.aspx/GetDatabaseCategoriesForTemplates', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' }
                })
                .then(r => r.json())
                .then(res => {
                    templateDbCategories = JSON.parse(res.d || "[]");
                    populateTemplateCategoryDropdowns();
                })
                .catch(err => {
                    console.error("Failed to load categories for templates:", err);
                    populateTemplateCategoryDropdowns();
                });
            }

            function populateTemplateCategoryDropdowns() {
                const wagesSelect = document.getElementById("wagesTplCategorySelect");
                const pocSelect = document.getElementById("pocRepCategorySelect");

                let cats = templateDbCategories;
                if (!cats || cats.length === 0) {
                    cats = [
                        { TierId: 1, TierName: "Skilled", DisplayName: "Skilled", RoleLabel: "DEO" },
                        { TierId: 2, TierName: "Semi-Skilled", DisplayName: "Semi-Skilled", RoleLabel: "Office Assistant" },
                        { TierId: 3, TierName: "Unskilled", DisplayName: "Unskilled", RoleLabel: "Attender" }
                    ];
                }

                if (wagesSelect) {
                    const currentWagesVal = wagesSelect.value;
                    wagesSelect.innerHTML = "";
                    cats.forEach(c => {
                        const opt = document.createElement("option");
                        opt.value = c.TierName;
                        const label = c.MainCategory ? `${c.MainCategory} › ${c.TierName}` : c.TierName;
                        opt.textContent = label + (c.RoleLabel ? ` (#${c.RoleLabel})` : "");
                        opt.setAttribute("data-tier-id", c.TierId);
                        opt.setAttribute("data-role-label", c.RoleLabel || "");
                        wagesSelect.appendChild(opt);
                    });
                    if (currentWagesVal && Array.from(wagesSelect.options).some(o => o.value === currentWagesVal)) {
                        wagesSelect.value = currentWagesVal;
                    }
                    onWagesTplCategoryChange();
                }

                if (pocSelect) {
                    const currentPocVal = pocSelect.value;
                    pocSelect.innerHTML = "";
                    cats.forEach(c => {
                        const opt = document.createElement("option");
                        opt.value = c.TierName;
                        const label = c.MainCategory ? `${c.MainCategory} › ${c.TierName}` : c.TierName;
                        opt.textContent = label + (c.RoleLabel ? ` (#${c.RoleLabel})` : "");
                        opt.setAttribute("data-tier-id", c.TierId);
                        opt.setAttribute("data-role-label", c.RoleLabel || "");
                        pocSelect.appendChild(opt);
                    });
                    if (currentPocVal && Array.from(pocSelect.options).some(o => o.value === currentPocVal)) {
                        pocSelect.value = currentPocVal;
                    }
                    onPocRepCategoryChange();
                }
            }

            function onWagesTplCategoryChange() {
                const catSelect = document.getElementById("wagesTplCategorySelect");
                if (!catSelect || !catSelect.value) return;
                const catVal = catSelect.value;
                const safeCat = catVal.replace(/-/g, '_').replace(/ /g, '_');
                const descInput = document.getElementById("wagesTplCategoryDescInput");
                if (descInput) {
                    descInput.value = wagesCategoryDescriptions[catVal] || wagesCategoryDescriptions[safeCat] || "";
                }
            }

            function onWagesTplCategoryDescInput() {
                const catSelect = document.getElementById("wagesTplCategorySelect");
                const descInput = document.getElementById("wagesTplCategoryDescInput");
                if (catSelect && descInput && catSelect.value) {
                    const catVal = catSelect.value;
                    const safeCat = catVal.replace(/-/g, '_').replace(/ /g, '_');
                    wagesCategoryDescriptions[catVal] = descInput.value;
                    wagesCategoryDescriptions[safeCat] = descInput.value;
                }
            }

            function saveWagesCurrentCategoryDesc() {
                const catSelect = document.getElementById("wagesTplCategorySelect");
                const descInput = document.getElementById("wagesTplCategoryDescInput");
                if (!catSelect || !catSelect.value || !descInput || !descInput.value.trim()) {
                    showToast("Category and Description cannot be empty.", "warning");
                    return;
                }
                const catVal = catSelect.value;
                const descVal = descInput.value.trim();

                fetch('Documents.aspx/SaveCategoryDescription', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        category: catVal,
                        description: descVal,
                        templateType: 'wages'
                    })
                })
                .then(r => r.json())
                .then(res => {
                    const data = JSON.parse(res.d || "{}");
                    if (data.status === "success") {
                        const safeCat = catVal.replace(/-/g, '_').replace(/ /g, '_');
                        wagesCategoryDescriptions[catVal] = descVal;
                        wagesCategoryDescriptions[safeCat] = descVal;
                        showToast(`Description for ${catVal} saved successfully.`, "success");
                    } else {
                        showToast(data.message || "Failed to save category description.", "error");
                    }
                })
                .catch(() => showToast("Error saving category description.", "error"));
            }

            function onPocRepCategoryChange() {
                const catSelect = document.getElementById("pocRepCategorySelect");
                if (!catSelect || !catSelect.value) return;
                const catVal = catSelect.value;
                const safeCat = catVal.replace(/-/g, '_').replace(/ /g, '_');
                const descInput = document.getElementById("pocRepCategoryDescInput");
                if (!descInput) return;

                const opt = catSelect.options[catSelect.selectedIndex];
                const roleLabel = opt ? opt.getAttribute("data-role-label") : "";

                const desc = pocRepCategoryDescriptions[catVal]
                          || pocRepCategoryDescriptions[safeCat]
                          || roleLabel
                          || wagesCategoryDescriptions[catVal]
                          || wagesCategoryDescriptions[safeCat]
                          || (catVal.toLowerCase().includes("semi") ? "Office Assistant" : "DEO");
                descInput.value = desc || "";
            }

            function onPocRepCategoryDescInput() {
                const catSelect = document.getElementById("pocRepCategorySelect");
                const descInput = document.getElementById("pocRepCategoryDescInput");
                if (catSelect && descInput && catSelect.value) {
                    const catVal = catSelect.value;
                    const safeCat = catVal.replace(/-/g, '_').replace(/ /g, '_');
                    pocRepCategoryDescriptions[catVal] = descInput.value;
                    pocRepCategoryDescriptions[safeCat] = descInput.value;
                }
            }

            function savePocRepCurrentCategoryDesc() {
                const catSelect = document.getElementById("pocRepCategorySelect");
                const descInput = document.getElementById("pocRepCategoryDescInput");
                if (!catSelect || !catSelect.value || !descInput || !descInput.value.trim()) {
                    showToast("Category and Manpower Description cannot be empty.", "warning");
                    return;
                }
                const catVal = catSelect.value;
                const descVal = descInput.value.trim();

                fetch('Documents.aspx/SaveCategoryDescription', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        category: catVal,
                        description: descVal,
                        templateType: 'poc_report'
                    })
                })
                .then(r => r.json())
                .then(res => {
                    const data = JSON.parse(res.d || "{}");
                    if (data.status === "success") {
                        const safeCat = catVal.replace(/-/g, '_').replace(/ /g, '_');
                        pocRepCategoryDescriptions[catVal] = descVal;
                        pocRepCategoryDescriptions[safeCat] = descVal;
                        showToast(`Manpower description for ${catVal} saved successfully.`, "success");
                    } else {
                        showToast(data.message || "Failed to save category description.", "error");
                    }
                })
                .catch(() => showToast("Error saving category description.", "error"));
            }

            // On Page Load
            document.addEventListener("DOMContentLoaded", () => {
                loadDatabaseCategoriesForTemplates().then(() => {
                    loadTemplates();
                });
                populateSelectors();
                // check for custom header on page load
                const savedHeader = localStorage.getItem('satisfactory_custom_header');
                if (savedHeader) {
                    const imgEl = document.getElementById('satPreviewHeaderImage');
                    if (imgEl) imgEl.src = savedHeader;
                }

                // Recalculate wages total when any cell is edited in the table
                const recalculateWagesFromTable = () => {
                    const dailyRateInput = parseFloat(document.getElementById("wagesDailyRate").value) || 0;
                    const epfRate = parseFloat(document.getElementById("wagesEpfRate").value) || 0;
                    const epfLimit = parseFloat(document.getElementById("wagesEpfLimit").value) || 0;
                    const serviceChargeRate = parseFloat(document.getElementById("wagesServiceChargeRate").value) || 0;
                    const gstRate = parseFloat(document.getElementById("wagesGstRate").value) || 0;
                    const epfMaxAmount = parseFloat(document.getElementById("wagesEpfCappedAmount").value) || 0;

                    let totalPeople = 0;
                    let totalWorkingDays = 0;
                    let wagesTotal = 0;
                    let epfCappedCount = 0;
                    let epfCappedTotal = 0;
                    let epfActualCount = 0;
                    let epfActualSum = 0;

                    const rows = document.querySelectorAll("#wagesTableBody tr");
                    rows.forEach(tr => {
                        const cells = tr.querySelectorAll("td");
                        if (cells.length < 6) return;

                        const cellDailyRate = parseFloat(cells[1].textContent.replace(/,/g, '')) || 0;
                        const cellPeople = parseInt(cells[3].textContent.replace(/,/g, '')) || 0;
                        const cellDays = parseFloat(cells[4].textContent.replace(/,/g, '')) || 0;

                        const cellPayment = cellDailyRate * cellDays;
                        const cellTotalDays = cellPeople * cellDays;

                        if (document.activeElement !== cells[2]) {
                            cells[2].textContent = cellPayment.toFixed(2);
                        }
                        if (document.activeElement !== cells[5]) {
                            cells[5].textContent = cellTotalDays.toFixed(0);
                        }

                        totalPeople += cellPeople;
                        totalWorkingDays += cellTotalDays;

                        if (cellPayment >= epfLimit) {
                            epfCappedCount += cellPeople;
                            epfCappedTotal += cellPeople * epfMaxAmount;
                        } else {
                            epfActualCount += cellPeople;
                            epfActualSum += cellPeople * (cellPayment * (epfRate / 100));
                        }
                    });

                    document.getElementById("wagesTotalPeople").textContent = totalPeople;
                    document.getElementById("wagesTotalDays").textContent = totalWorkingDays;

                    document.getElementById("wagesFormulaDesc").textContent = `${dailyRateInput.toFixed(2)}*${totalWorkingDays}`;
                    wagesTotal = totalWorkingDays * dailyRateInput;

                    if (document.activeElement !== document.getElementById("wagesAmountWages")) {
                        document.getElementById("wagesAmountWages").textContent = wagesTotal.toFixed(2);
                    } else {
                        wagesTotal = parseFloat(document.getElementById("wagesAmountWages").textContent.replace(/,/g, '')) || 0;
                    }

                    document.getElementById("wagesFormulaEpfCapped").textContent = `EPF @${epfRate}%for ${epfCappedCount} persons`;

                    if (document.activeElement !== document.getElementById("wagesAmountEpfCapped")) {
                        document.getElementById("wagesAmountEpfCapped").textContent = epfCappedTotal.toFixed(2);
                    } else {
                        epfCappedTotal = parseFloat(document.getElementById("wagesAmountEpfCapped").textContent.replace(/,/g, '')) || 0;
                    }

                    document.getElementById("wagesFormulaEpfActual").textContent = `EPF @${epfRate}%for ${epfActualCount} person`;

                    if (document.activeElement !== document.getElementById("wagesAmountEpfActual")) {
                        document.getElementById("wagesAmountEpfActual").textContent = epfActualSum.toFixed(2);
                    } else {
                        epfActualSum = parseFloat(document.getElementById("wagesAmountEpfActual").textContent.replace(/,/g, '')) || 0;
                    }

                    let subTotal = wagesTotal + epfCappedTotal + epfActualSum;
                    if (document.activeElement !== document.getElementById("wagesAmountSubTotal")) {
                        document.getElementById("wagesAmountSubTotal").textContent = subTotal.toFixed(2);
                    } else {
                        subTotal = parseFloat(document.getElementById("wagesAmountSubTotal").textContent.replace(/,/g, '')) || 0;
                    }

                    let serviceCharge = subTotal * (serviceChargeRate / 100);
                    let scFormulaText = `Service Charge  @${serviceChargeRate.toFixed(2)}% `;
                    if (window.wagesAltScEnabled && window.wagesAltScData && window.wagesAltScData.serviceCharge > 0) {
                        serviceCharge = window.wagesAltScData.serviceCharge;
                        scFormulaText = `Service Charge  @${window.wagesAltScData.scRate.toFixed(2)}% `;
                    }

                    if (document.activeElement !== document.getElementById("wagesAmountServiceCharge")) {
                        document.getElementById("wagesAmountServiceCharge").textContent = serviceCharge.toFixed(2);
                    } else {
                        serviceCharge = parseFloat(document.getElementById("wagesAmountServiceCharge").textContent.replace(/,/g, '')) || 0;
                    }
                    const scFormulaEl = document.getElementById("wagesFormulaServiceCharge");
                    if (scFormulaEl) scFormulaEl.textContent = scFormulaText;

                    let gst = subTotal * (gstRate / 100);
                    if (document.activeElement !== document.getElementById("wagesAmountGst")) {
                        document.getElementById("wagesAmountGst").textContent = gst.toFixed(2);
                    } else {
                        gst = parseFloat(document.getElementById("wagesAmountGst").textContent.replace(/,/g, '')) || 0;
                    }

                    const grandTotal = subTotal + serviceCharge + gst;
                    document.getElementById("wagesAmountGrandTotal").textContent = grandTotal.toFixed(2);
                };

                const wagesTable = document.getElementById("wagesTable");
                if (wagesTable) {
                    wagesTable.addEventListener("input", recalculateWagesFromTable);
                }
            });

            // -- Covering Letter Scripts --
            let divisions = [];

            function getOrdinalSuffix(day) {
                if (day > 3 && day < 21) return 'th';
                switch (day % 10) {
                    case 1: return "st";
                    case 2: return "nd";
                    case 3: return "rd";
                    default: return "th";
                }
            }

            function populateCovSelectors() {
                const yearSel = document.getElementById("covYear");
                const monthSel = document.getElementById("covMonth");
                const categorySel = document.getElementById("covCategory");
                const divisionSel = document.getElementById("covDivision");

                // Fill Year if empty
                if (yearSel.innerHTML === "") {
                    const currYear = new Date().getFullYear();
                    for (let y = currYear - 2; y <= currYear + 2; y++) {
                        yearSel.innerHTML += `<option value="${y}">${y}</option>`;
                    }
                    yearSel.value = currYear;
                }

                // Fill Month if empty
                if (monthSel.innerHTML === "") {
                    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                    months.forEach((m, i) => {
                        monthSel.innerHTML += `<option value="${i}">${m}</option>`;
                    });
                    monthSel.value = new Date().getMonth();
                }

                // Fill Category
                if (categorySel.innerHTML === "" || categorySel.options.length <= 1) {
                    fillCategoryDropdown(categorySel);
                }

                // Fill Division if empty
                if (divisionSel.innerHTML === "") {
                    if (divisions.length > 0) {
                        fillDivisionDropdown();
                        onCovFilterChange();
                    } else {
                        fetch('Documents.aspx/GetDivisions', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' }
                        })
                            .then(r => r.json())
                            .then(res => {
                                divisions = JSON.parse(res.d || "[]");
                                fillDivisionDropdown();
                                onCovFilterChange();
                            })
                            .catch(() => {
                                showToast("Failed to fetch divisions.", "error");
                                onCovFilterChange();
                            });
                    }
                } else {
                    onCovFilterChange();
                }
            }

            function fillDivisionDropdown() {
                const divisionSel = document.getElementById("covDivision");
                divisionSel.innerHTML = "";
                divisions.forEach(div => {
                    divisionSel.innerHTML += `<option value="${div}">${div}</option>`;
                });
                // Default to D-KRM if it exists
                const defaultDiv = divisions.find(d => d === "D-KRM");
                if (defaultDiv) {
                    divisionSel.value = "D-KRM";
                } else if (divisions.length > 0) {
                    divisionSel.value = divisions[0];
                }
            }

            function onCovFilterChange() {
                const yearElem = document.getElementById("covYear");
                const monthElem = document.getElementById("covMonth");
                const catElem = document.getElementById("covCategory");
                if (!yearElem || !monthElem || !catElem || !yearElem.value || !monthElem.value || !catElem.value) return;
                const yearVal = parseInt(yearElem.value);
                const monthVal = parseInt(monthElem.value);
                const catVal = catElem.value;
                if (isNaN(yearVal) || isNaN(monthVal)) return;

                if (catVal === "All") {
                    document.getElementById("covContractGroup").style.display = "none";
                    document.getElementById("covContract").innerHTML = "";
                    updateCovPreview();
                    return;
                }

                // Fetch Contracts
                fetch('Documents.aspx/GetContractsForMonth', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ year: yearVal, month: monthVal, category: catVal })
                })
                    .then(r => r.json())
                    .then(res => {
                        covContractsList = JSON.parse(res.d || "[]");
                        const contractSel = document.getElementById("covContract");
                        const contractGroup = document.getElementById("covContractGroup");

                        if (covContractsList.length > 0) {
                            let optionsHtml = "";
                            covContractsList.forEach(c => {
                                optionsHtml += `<option value="${c.Id}">${c.DisplayName}</option>`;
                            });
                            contractSel.innerHTML = optionsHtml;
                            contractGroup.style.display = "block";
                            onCovContractChange();
                        } else {
                            contractGroup.style.display = "none";
                            contractSel.innerHTML = "";
                            updateCovPreview();
                        }
                    })
                    .catch(() => showToast("Failed to fetch contract periods.", "error"));
            }

            function onCovContractChange() {
                updateCovPreview();
            }

            function updateCovPreview() {
                const contractSel = document.getElementById("covContract");
                const selectedId = contractSel && contractSel.value ? parseInt(contractSel.value) : null;
                const contract = covContractsList.find(c => c.Id === selectedId);

                const vendorName = contract ? contract.VendorName : "[Vendor Name]";
                const vendorAddress = contract ? contract.VendorAddress : "[Vendor Address]";

                const ySelect = document.getElementById("covYear");
                if (!ySelect || !ySelect.value) return;
                const yText = ySelect.value;

                const mSelect = document.getElementById("covMonth");
                if (!mSelect || mSelect.selectedIndex === -1) return;
                const mText = mSelect.options[mSelect.selectedIndex].text;

                const daysInMonth = new Date(parseInt(yText), parseInt(mSelect.value) + 1, 0).getDate();

                // Date of covering letter: usually the month after the selected month (e.g. May 2026 selected -> June 2026)
                let nextMonthIndex = (parseInt(mSelect.value) + 1) % 12;
                let nextYear = parseInt(yText);
                if (nextMonthIndex === 0) nextYear += 1;
                const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
                const certMonthText = months[nextMonthIndex];

                // Formatted date period: e.g. 01st May 2026 to 31st May 2026
                const fullMonthName = months[parseInt(mSelect.value)];
                const formattedStart = `01st ${fullMonthName} ${yText}`;
                const formattedEnd = `${daysInMonth}${getOrdinalSuffix(daysInMonth)} ${fullMonthName} ${yText}`;

                // Read the template values from inputs
                const phone = document.getElementById("covPhoneInput").value || "";
                const refNoTpl = document.getElementById("covRefNoInput").value || "";
                const subject = document.getElementById("covSubjectInput").value || "";
                const bodyTpl = document.getElementById("covBodyInput").value || "";
                const signatory = document.getElementById("covSignatoryInput").value || "";
                const designation = document.getElementById("covDesignationInput").value || "";
                const authorityTpl = document.getElementById("covAuthorityInput").value || "";
                const recipientTpl = document.getElementById("covRecipientInput").value || "";

                const catVal = document.getElementById("covCategory").value;
                const catLabel = catVal !== "All" ? catVal.toLowerCase() : "contract staff";
                const divisionVal = document.getElementById("covDivision").value || "[Division]";

                // Placeholders replacements
                let refNo = replacePlaceholders(refNoTpl, "covering");
                let authority = replacePlaceholders(authorityTpl, "covering");
                let recipient = replacePlaceholders(recipientTpl, "covering");
                let body = replacePlaceholders(bodyTpl, "covering");

                // Bind to Preview UI elements
                document.getElementById("covPreviewPhone").textContent = phone;
                document.getElementById("covPreviewRefNo").textContent = refNo;
                document.getElementById("covPreviewDate").textContent = `${certMonthText} ${nextYear}`;
                document.getElementById("covPreviewDivision").textContent = divisionVal;
                document.getElementById("covPreviewSubject").textContent = subject;

                document.getElementById("covParagraph").innerHTML = body.replace(/\n/g, '<br/>');

                document.getElementById("covPreviewSignatory").textContent = signatory;
                document.getElementById("covPreviewDesignation").textContent = designation;
                document.getElementById("covPreviewAuthority").textContent = authority;

                document.getElementById("covRecipient").innerHTML = recipient.replace(/\n/g, '<br/>');

                document.getElementById("covPreviewArea").style.display = "block";
                updateCovMiniPreview();
            }

            function saveCovTpl() {
                const phone = document.getElementById("covPhoneInput").value;
                const refNo = document.getElementById("covRefNoInput").value;
                const subject = document.getElementById("covSubjectInput").value;
                const body = document.getElementById("covBodyInput").value;
                const signatory = document.getElementById("covSignatoryInput").value;
                const designation = document.getElementById("covDesignationInput").value;
                const authority = document.getElementById("covAuthorityInput").value;
                const recipient = document.getElementById("covRecipientInput").value;
                const pcno = document.getElementById("covSignatoryPcnoInput")?.value || "";
                const fontSizePt = parseInt(document.getElementById('covFontSizeInput')?.value) || 12;
                const sectionSpacingPt = parseInt(document.getElementById('covSectionSpacingInput')?.value) || 24;
                const sigSpacingPt = parseInt(document.getElementById('covSigSpacingInput')?.value) || 50;

                if (!phone.trim() || !refNo.trim() || !subject.trim() || !body.trim() || !signatory.trim() || !designation.trim() || !authority.trim() || !recipient.trim()) {
                    showToast("All fields are required and cannot be empty.", "warning");
                    return;
                }

                fetch('Documents.aspx/SaveCovTemplates', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        phone: phone,
                        refNo: refNo,
                        subject: subject,
                        body: body,
                        signatory: signatory,
                        designation: designation,
                        authority: authority,
                        recipient: recipient,
                        pcno: pcno,
                        fontSizePt: fontSizePt,
                        sectionSpacingPt: sectionSpacingPt,
                        sigSpacingPt: sigSpacingPt
                    })
                })
                    .then(r => r.json())
                    .then(res => {
                        const data = JSON.parse(res.d || "{}");
                        if (data.status === "success") {
                            tplCovPhone = phone;
                            tplCovRefNo = refNo;
                            tplCovSubject = subject;
                            tplCovBody = body;
                            tplCovSignatory = signatory;
                            tplCovDesignation = designation;
                            tplCovAuthority = authority;
                            tplCovRecipient = recipient;
                            applyCovLayout(fontSizePt, sectionSpacingPt, sigSpacingPt);
                            showToast("Covering Letter settings saved successfully.", "success");
                            updateCovPreview();
                        } else {
                            showToast(data.message || "Failed to save.", "error");
                        }
                    })
                    .catch(() => showToast("Error saving templates.", "error"));
            }

            function fetchCovSignatoryDetails() {
                const pcnoInput = document.getElementById("covSignatoryPcnoInput");
                const pcno = pcnoInput ? pcnoInput.value.trim() : "";
                if (!pcno) {
                    showToast("Please enter a PCNO first.", "warning");
                    return;
                }

                showToast("Fetching signatory details...", "info");

                fetch('Documents.aspx/GetEmployeeDetailsByPCNO', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ pcno: pcno })
                })
                .then(r => r.json())
                .then(res => {
                    const data = JSON.parse(res.d || "{}");
                    if (data.status === "success") {
                        const sigInput = document.getElementById("covSignatoryInput");
                        const desInput = document.getElementById("covDesignationInput");
                        
                        if (sigInput) sigInput.value = data.name || "";
                        if (desInput) desInput.value = data.designation || "";
                        
                        showToast("Signatory details fetched successfully!", "success");
                        updateCovPreview();
                    } else {
                        showToast(data.message || "Failed to fetch details.", "error");
                    }
                })
                .catch(err => {
                    console.error(err);
                    showToast("Error communicating with backend.", "error");
                });
            }

            function downloadCovAsDoc() {
                const sheet = document.getElementById('coveringLetterPrintSheet');
                if (!sheet) { showToast("Covering Letter preview not loaded.", "error"); return; }

                const txt = id => { const el = document.getElementById(id); return el ? el.textContent : ''; };

                // Read live covering letter layout settings
                const docFontSize = parseInt(document.getElementById('covFontSizeInput')?.value) || 12;
                const docSectionSpacing = parseInt(document.getElementById('covSectionSpacingInput')?.value) || 24;
                const docSigSpacing = parseInt(document.getElementById('covSigSpacingInput')?.value) || 50;

                const html = `<html xmlns:o="urn:schemas-microsoft-com:office:office"
xmlns:w="urn:schemas-microsoft-com:office:word"
xmlns="http://www.w3.org/TR/REC-html40">
<head>
<meta charset="UTF-8"/>
<meta name="ProgId" content="Word.Document"/>
<meta name="Generator" content="Microsoft Word 15"/>
<meta name="Originator" content="Microsoft Word 15"/>
<!--[if gte mso 9]><xml>
<w:WordDocument>
  <w:View>Print</w:View>
  <w:Zoom>100</w:Zoom>
  <w:DoNotOptimizeForBrowser/>
</w:WordDocument>
</xml><![endif]-->
<style>
@page Section1 {
  size: 595.3pt 841.9pt;
  margin: 72.0pt 72.0pt 72.0pt 72.0pt;
  mso-header-margin: 36.0pt;
  mso-footer-margin: 36.0pt;
  mso-paper-source: 0;
}
div.Section1 { page: Section1; }
body {
  margin: 0;
  padding: 0;
  font-family: Arial, Helvetica, sans-serif;
  font-size: ${docFontSize}.0pt;
  color: black;
}
p { margin: 0; padding: 0; }
</style>
</head>
<body lang="EN-IN">
<div class="Section1">

<!-- Phone No (Internal) -->
<p style="text-align:left;font-family: Arial, Helvetica, sans-serif;font-size:${docFontSize}.0pt;margin-bottom:${docSectionSpacing / 2}pt;">
  Phone No (Internal): ${txt('covPreviewPhone')}
</p>

<!-- Reference Number & Date table -->
<table border="0" cellpadding="0" cellspacing="0" style="width:100%;border:none;border-collapse:collapse;margin-bottom:${docSectionSpacing}pt;">
  <tr>
    <td align="left" style="text-align:left;font-family: Arial, Helvetica, sans-serif;font-size:${docFontSize}.0pt;padding:0;width:50%;">
      No: ${txt('covPreviewRefNo')}
    </td>
    <td align="right" style="text-align:right;font-family: Arial, Helvetica, sans-serif;font-size:${docFontSize}.0pt;font-weight:bold;padding:0;width:50%;">
      ${txt('covPreviewDate')}
    </td>
  </tr>
</table>

<!-- Division -->
<p style="text-align:center;font-family: Arial, Helvetica, sans-serif;font-size:${docFontSize}.0pt;font-weight:bold;margin-bottom:${docSectionSpacing / 2}pt;">
  ${txt('covPreviewDivision')}
</p>

<!-- Subject -->
<p style="text-align:center;font-family: Arial, Helvetica, sans-serif;font-size:${docFontSize}.0pt;font-weight:bold;margin-bottom:${docSectionSpacing}pt;text-transform:uppercase;">
  ${txt('covPreviewSubject')}
</p>

<p style="text-align:left;text-indent:36.0pt;font-family: Arial, Helvetica, sans-serif;font-size:${docFontSize}.0pt;line-height:150%;margin-bottom:${docSigSpacing}pt;">${document.getElementById('covParagraph').innerHTML.trim()}</p>

<!-- Signatory Block -->
<table align="right" border="0" cellpadding="0" cellspacing="0" style="margin-top:20pt;margin-bottom:${docSectionSpacing}pt;border:none;border-collapse:collapse;">
  <tr>
    <td align="center" style="text-align:center;font-family: Arial, Helvetica, sans-serif;font-size:${docFontSize}.0pt;padding:0;">
      <b>${txt('covPreviewSignatory')}</b>
    </td>
  </tr>
  <tr>
    <td align="center" style="text-align:center;font-family: Arial, Helvetica, sans-serif;font-size:${docFontSize}.0pt;padding:0;">
      ${txt('covPreviewDesignation')}
    </td>
  </tr>
  <tr>
    <td align="center" style="text-align:center;font-family: Arial, Helvetica, sans-serif;font-size:${docFontSize}.0pt;padding:0;">
      ${txt('covPreviewAuthority')}
    </td>
  </tr>
</table>
<div style="clear:both;"></div>

<!-- Recipient Block -->
<p style="text-align:left;font-family: Arial, Helvetica, sans-serif;font-size:${docFontSize}.0pt;font-weight:bold;margin-top:30pt;line-height:150%;">
  ${document.getElementById('covRecipient').innerHTML}
</p>

</div>
</body>
</html>`;

                const mSel = document.getElementById('covMonth');
                const ySel = document.getElementById('covYear');
                const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                const mName = mSel ? months[parseInt(mSel.value)] : 'Month';
                const yName = ySel ? ySel.value : 'Year';

                const blob = new Blob(['\ufeff', html], { type: 'application/msword' });
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = `Covering_Letter_${mName}_${yName}.doc`;
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                URL.revokeObjectURL(url);
                showToast("Covering Letter downloaded as DOC.", "success");
            }

            // -- Satisfactory Certificate Scripts --
            let satContractsList = [];
            let satEmployeesData = [];

            function populateSatSelectors() {
                const yearSel = document.getElementById("satYear");
                const monthSel = document.getElementById("satMonth");
                const categorySel = document.getElementById("satCategory");

                // Fill Year if empty
                if (yearSel.innerHTML === "") {
                    const currYear = new Date().getFullYear();
                    for (let y = currYear - 2; y <= currYear + 2; y++) {
                        yearSel.innerHTML += `<option value="${y}">${y}</option>`;
                    }
                    yearSel.value = currYear;
                }

                // Fill Month if empty
                if (monthSel.innerHTML === "") {
                    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                    months.forEach((m, i) => {
                        monthSel.innerHTML += `<option value="${i}">${m}</option>`;
                    });
                    monthSel.value = new Date().getMonth();
                }

                // Fill Category
                if (categorySel.innerHTML === "" || categorySel.options.length <= 1) {
                    fillCategoryDropdown(categorySel);
                }

                // Load saved custom header if exists
                const savedHeader = localStorage.getItem('satisfactory_custom_header');
                if (savedHeader) {
                    const imgEl = document.getElementById('satPreviewHeaderImage');
                    if (imgEl) imgEl.src = savedHeader;
                }

                onSatFilterChange();
            }

            function onSatFilterChange() {
                const yearElem = document.getElementById("satYear");
                const monthElem = document.getElementById("satMonth");
                const catElem = document.getElementById("satCategory");
                if (!yearElem || !monthElem || !catElem || !yearElem.value || !monthElem.value || !catElem.value) return;
                const yearVal = parseInt(yearElem.value);
                const monthVal = parseInt(monthElem.value);
                const catVal = catElem.value;
                if (isNaN(yearVal) || isNaN(monthVal)) return;

                if (catVal === "All") {
                    document.getElementById("satContractGroup").style.display = "none";
                    document.getElementById("satContract").innerHTML = "";
                    clearSatInputs();
                    updateSatPreview();
                    loadSatData();
                    return;
                }

                // Fetch Contracts using existing WebMethod
                fetch('Documents.aspx/GetContractsForMonth', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ year: yearVal, month: monthVal, category: catVal })
                })
                    .then(r => r.json())
                    .then(res => {
                        satContractsList = JSON.parse(res.d || "[]");
                        const contractSel = document.getElementById("satContract");
                        const contractGroup = document.getElementById("satContractGroup");

                        if (satContractsList.length > 0) {
                            let optionsHtml = "";
                            satContractsList.forEach(c => {
                                optionsHtml += `<option value="${c.Id}">${c.DisplayName}</option>`;
                            });
                            contractSel.innerHTML = optionsHtml;
                            contractGroup.style.display = "block";
                            onSatContractChange();
                        } else {
                            contractGroup.style.display = "none";
                            contractSel.innerHTML = "";
                            clearSatInputs();
                            updateSatPreview();
                            loadSatData();
                        }
                    })
                    .catch(() => showToast("Failed to fetch contract periods.", "error"));
            }

            function clearSatInputs() {
                document.getElementById("satVendorNameInput").value = "";
                document.getElementById("satVendorAddressInput").value = "";
                document.getElementById("satGemNoInput").value = "";
                document.getElementById("satContractDateInput").value = "";
                document.getElementById("satWefInput").value = "";
                document.getElementById("satDatedOnInput").value = "";
                document.getElementById("satEmpCountInput").value = "0";
            }

            function onSatContractChange() {
                const contractSel = document.getElementById("satContract");
                const selectedId = parseInt(contractSel.value);
                const contract = satContractsList.find(c => c.Id === selectedId);

                if (contract) {
                    document.getElementById("satVendorNameInput").value = contract.VendorName || "";
                    document.getElementById("satVendorAddressInput").value = contract.VendorAddress || "";
                    document.getElementById("satGemNoInput").value = contract.GemId || "";
                    document.getElementById("satContractDateInput").value = contract.StartDate || ""; // Prefill with contract date
                    document.getElementById("satWefInput").value = contract.StartDate || ""; // w.e.f. date is contract start date
                    document.getElementById("satDatedOnInput").value = contract.VendorDatedOn || "";
                }
                updateSatPreview();
                loadSatData();
            }

            function loadSatData() {
                const loader = document.getElementById("satPreviewLoader");
                const previewArea = document.getElementById("satPreviewArea");

                loader.style.display = "block";
                previewArea.style.display = "none";

                const yearVal = parseInt(document.getElementById("satYear").value);
                const monthVal = parseInt(document.getElementById("satMonth").value);
                const catVal = document.getElementById("satCategory").value;
                const contractSel = document.getElementById("satContract");
                const selectedCpId = contractSel && contractSel.value ? parseInt(contractSel.value) : null;

                // Fetch Live Attendance / Employee count using existing WebMethod
                fetch('Documents.aspx/GetCertificateData', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ year: yearVal, month: monthVal, category: catVal, contractPeriodId: selectedCpId })
                })
                    .then(r => r.json())
                    .then(res => {
                        satEmployeesData = JSON.parse(res.d || "[]");
                        if (satEmployeesData.error) {
                            showToast(satEmployeesData.error, "error");
                            loader.style.display = "none";
                            return;
                        }

                        // Prefill employee count
                        document.getElementById("satEmpCountInput").value = satEmployeesData.length;

                        updateSatPreview();
                        loader.style.display = "none";
                        previewArea.style.display = "block";
                        showToast(`Loaded ${satEmployeesData.length} records successfully!`, "success");
                    })
                    .catch(() => {
                        loader.style.display = "none";
                        showToast("Failed to retrieve satisfactory certificate data.", "error");
                    });
            }

            function updateSatPreview() {
                const vendorName = document.getElementById("satVendorNameInput").value || "[Vendor Name]";
                const vendorAddress = document.getElementById("satVendorAddressInput").value || "[Vendor Address]";
                const gemNo = document.getElementById("satGemNoInput").value || "[GeM Contract No]";
                const contractDate = document.getElementById("satContractDateInput").value || "[Contract Date]";
                const datedOn = document.getElementById("satDatedOnInput").value || "[Dated On]";
                const duration = document.getElementById("satDurationInput").value || "[Period]";
                const wefDate = document.getElementById("satWefInput").value || "[w.e.f. Date]";
                const services = document.getElementById("satServicesInput").value || "[Services Description]";
                const empCount = document.getElementById("satEmpCountInput").value || "0";
                const signatory = document.getElementById("satSignatoryInput").value || "[Signatory Name]";
                const designation = document.getElementById("satDesignationInput").value || "[Signatory Designation]";

                const ySelect = document.getElementById("satYear");
                if (!ySelect || !ySelect.value) return;
                const yText = ySelect.value;

                const mSelect = document.getElementById("satMonth");
                if (!mSelect || mSelect.selectedIndex === -1) return;
                const mText = mSelect.options[mSelect.selectedIndex].text;

                const daysInMonth = new Date(parseInt(yText), parseInt(mSelect.value) + 1, 0).getDate();

                // Date of certificate: usually the month after the selected month (e.g. May 2026 selected -> prints June 2026)
                let nextMonthIndex = (parseInt(mSelect.value) + 1) % 12;
                let nextYear = parseInt(yText);
                if (nextMonthIndex === 0) nextYear += 1;
                const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
                const certMonthText = months[nextMonthIndex];

                document.getElementById("satPreviewDate").textContent = `${certMonthText}  ${nextYear}`;

                // Formatted date period: e.g. 01 May 2026 to 31 May 2026
                const fullMonthName = months[parseInt(mSelect.value)];
                const formattedStart = `01 ${fullMonthName.substring(0, 3)} ${yText}`;
                const formattedEnd = `${daysInMonth} ${fullMonthName.substring(0, 3)} ${yText}`;

                // Sentence replacements from textareas (matching default fallbacks)
                const tpl1 = document.getElementById("txtSatTplDesc1")?.value || tplSatDesc1;
                const tpl2 = document.getElementById("txtSatTplDesc2")?.value || tplSatDesc2;
                const tpl3 = document.getElementById("txtSatTplDesc3")?.value || tplSatDesc3;

                let p1 = replacePlaceholders(tpl1, "satisfactory");
                let p2 = replacePlaceholders(tpl2, "satisfactory");
                let p3 = replacePlaceholders(tpl3, "satisfactory");

                document.getElementById("satParagraph1").innerHTML = p1.trim();
                document.getElementById("satParagraph2").innerHTML = p2.trim();
                document.getElementById("satParagraph3").innerHTML = p3.trim();

                document.getElementById("satPreviewSignatory").textContent = signatory;
                document.getElementById("satPreviewDesignation").textContent = designation;
                updateSatMiniPreview();
            }

            // Applies font size and spacing to both on-screen preview and @media print CSS
            function applySatLayout(fontSizePt, sectionSpacingPt, sigSpacingPt) {
                fontSizePt = parseInt(fontSizePt) || 14;
                sectionSpacingPt = parseInt(sectionSpacingPt) || 25;
                sigSpacingPt = parseInt(sigSpacingPt) || 50;

                // Update the on-screen preview container font
                const sheet = document.getElementById('satisfactoryPrintSheet');
                if (sheet) sheet.style.fontSize = fontSizePt + 'pt';

                // Update margins on all section wrappers
                const sectionMargin = sectionSpacingPt + 'pt';
                const headerWrap = document.querySelector('.sat-header-img-wrap');
                const dateWrap = document.querySelector('.sat-date-wrap');
                const titleWrap = document.querySelector('.sat-title-wrap');
                const p1 = document.getElementById('satParagraph1');
                const p2 = document.getElementById('satParagraph2');
                const p3 = document.getElementById('satParagraph3');
                if (headerWrap) headerWrap.style.marginBottom = sectionMargin;
                if (dateWrap) dateWrap.style.marginBottom = sectionMargin;
                if (titleWrap) titleWrap.style.marginBottom = sectionMargin;
                if (p1) p1.style.marginBottom = sectionMargin;
                if (p2) p2.style.marginBottom = sectionMargin;
                if (p3) p3.style.marginBottom = sigSpacingPt + 'pt';

                // Inject/update dynamic @media print CSS so print view matches preview
                let dynStyle = document.getElementById('satDynamicPrintCSS');
                if (!dynStyle) {
                    dynStyle = document.createElement('style');
                    dynStyle.id = 'satDynamicPrintCSS';
                    document.head.appendChild(dynStyle);
                }
                dynStyle.textContent = `@media print {
                #satisfactoryPrintSheet { font-size: ${fontSizePt}pt !important; }
                .sat-header-img-wrap  { margin-bottom: ${sectionSpacingPt}pt !important; }
                .sat-date-wrap        { margin-bottom: ${sectionSpacingPt}pt !important; }
                .sat-title-wrap       { margin-bottom: ${sectionSpacingPt}pt !important; font-size: ${fontSizePt}pt !important; }
                .sat-paragraph-wrap   { margin-bottom: ${sectionSpacingPt}pt !important; font-size: ${fontSizePt}pt !important; text-align: justify !important; }
                #satParagraph3.sat-paragraph-wrap { margin-bottom: ${sigSpacingPt}pt !important; }
            }`;
            }

            // Live preview when admin edits the Layout settings sliders
            function previewSatLayout() {
                const fs = parseInt(document.getElementById('satFontSizeInput')?.value) || 14;
                const ss = parseInt(document.getElementById('satSectionSpacingInput')?.value) || 25;
                const sig = parseInt(document.getElementById('satSigSpacingInput')?.value) || 50;
                applySatLayout(fs, ss, sig);
                updateSatMiniPreview();
            }

            // Update the mini preview panel in the Satisfactory Certificate template tab
            function updateSatMiniPreview() {
                const fs = parseInt(document.getElementById('satFontSizeInput')?.value) || 14;
                const ss = parseInt(document.getElementById('satSectionSpacingInput')?.value) || 25;
                const sig = parseInt(document.getElementById('satSigSpacingInput')?.value) || 50;
                const sheet = document.getElementById('satMiniPreviewSheet');
                if (!sheet) return;
                sheet.style.fontSize = fs + 'pt';
                // Section margins
                const sm = ss + 'pt';
                const sections = [
                    { id: 'satMiniP1', mb: sm }, { id: 'satMiniP2', mb: sm },
                    { id: 'satMiniP3', mb: sig + 'pt' }
                ];
                // Update header/date/title wrappers via inline style
                const children = sheet.children;
                if (children[0]) children[0].style.marginBottom = sm; // header img
                if (children[1]) children[1].style.marginBottom = sm; // date
                if (children[2]) children[2].style.marginBottom = sm; // title
                sections.forEach(s => { const el = document.getElementById(s.id); if (el) el.style.marginBottom = s.mb; });

                // Sync text content from main template inputs
                const p1Tpl = document.getElementById('txtSatTplDesc1')?.value;
                const p2Tpl = document.getElementById('txtSatTplDesc2')?.value;
                const p3Tpl = document.getElementById('txtSatTplDesc3')?.value;
                const sig_name = document.getElementById('satSignatoryInput')?.value || '(Signatory Name)';
                const sig_des = document.getElementById('satDesignationInput')?.value || 'Designation';
                if (document.getElementById('satMiniP1') && p1Tpl) document.getElementById('satMiniP1').innerHTML = p1Tpl.replace(/\{[^}]+\}/g, m => `<b style="color:#94a3b8">${m}</b>`);
                if (document.getElementById('satMiniP2') && p2Tpl) document.getElementById('satMiniP2').innerHTML = p2Tpl.replace(/\{[^}]+\}/g, m => `<b style="color:#94a3b8">${m}</b>`);
                if (document.getElementById('satMiniP3') && p3Tpl) document.getElementById('satMiniP3').innerHTML = p3Tpl.replace(/\{[^}]+\}/g, m => `<b style="color:#94a3b8">${m}</b>`);
                if (document.getElementById('satMiniSignatory')) document.getElementById('satMiniSignatory').textContent = sig_name;
                if (document.getElementById('satMiniDesignation')) document.getElementById('satMiniDesignation').textContent = sig_des;
                // Sync header image
                const mainImg = document.getElementById('satPreviewHeaderImage');
                const miniImg = document.getElementById('satMiniHeaderImg');
                if (mainImg && miniImg && mainImg.src) miniImg.src = mainImg.src;
            }

            // Applies font size and spacing to the covering letter preview and @media print CSS
            function applyCovLayout(fontSizePt, sectionSpacingPt, sigSpacingPt) {
                fontSizePt = parseInt(fontSizePt) || 12;
                sectionSpacingPt = parseInt(sectionSpacingPt) || 24;
                sigSpacingPt = parseInt(sigSpacingPt) || 50;

                // Update on-screen preview
                const sheet = document.getElementById('coveringLetterPrintSheet');
                if (sheet) sheet.style.fontSize = fontSizePt + 'pt';

                const sm = sectionSpacingPt + 'pt';
                const phoneWrap = document.querySelector('.cov-phone-wrap');
                const refDateWrap = document.querySelector('.cov-ref-date-wrap');
                const divWrap = document.querySelector('.cov-division-wrap');
                const subWrap = document.querySelector('.cov-subject-wrap');
                const paraWrap = document.getElementById('covParagraph');
                const sigWrap = document.querySelector('.cov-sig-wrap');
                if (phoneWrap) phoneWrap.style.marginBottom = sm;
                if (refDateWrap) refDateWrap.style.marginBottom = sm;
                if (divWrap) divWrap.style.marginBottom = sm;
                if (subWrap) subWrap.style.marginBottom = sm;
                if (paraWrap) paraWrap.style.marginBottom = sigSpacingPt + 'pt';
                if (sigWrap) { sigWrap.style.marginTop = '0'; sigWrap.style.marginBottom = sm; }

                // Inject dynamic print CSS
                let dynStyle = document.getElementById('covDynamicPrintCSS');
                if (!dynStyle) {
                    dynStyle = document.createElement('style');
                    dynStyle.id = 'covDynamicPrintCSS';
                    document.head.appendChild(dynStyle);
                }
                dynStyle.textContent = `@media print {
                #coveringLetterPrintSheet { font-size: ${fontSizePt}pt !important; }
                .cov-phone-wrap    { margin-bottom: ${sectionSpacingPt}pt !important; }
                .cov-ref-date-wrap { margin-bottom: ${sectionSpacingPt}pt !important; }
                .cov-division-wrap { margin-bottom: ${sectionSpacingPt}pt !important; }
                .cov-subject-wrap  { margin-bottom: ${sectionSpacingPt}pt !important; }
                #covParagraph      { margin-bottom: ${sigSpacingPt}pt !important; font-size: ${fontSizePt}pt !important; }
                .cov-sig-wrap      { margin-top: 0 !important; margin-bottom: ${sectionSpacingPt}pt !important; }
                .cov-recipient-wrap { font-size: ${fontSizePt}pt !important; }
            }`;
            }

            // Live preview when admin edits covering letter layout settings
            function previewCovLayout() {
                const fs = parseInt(document.getElementById('covFontSizeInput')?.value) || 12;
                const ss = parseInt(document.getElementById('covSectionSpacingInput')?.value) || 24;
                const sig = parseInt(document.getElementById('covSigSpacingInput')?.value) || 50;
                applyCovLayout(fs, ss, sig);
                updateCovMiniPreview();
            }

            // Update the mini preview panel in the Covering Letter template tab
            function updateCovMiniPreview() {
                const fs = parseInt(document.getElementById('covFontSizeInput')?.value) || 12;
                const ss = parseInt(document.getElementById('covSectionSpacingInput')?.value) || 24;
                const sig = parseInt(document.getElementById('covSigSpacingInput')?.value) || 50;
                const sheet = document.getElementById('covMiniPreviewSheet');
                if (!sheet) return;
                sheet.style.fontSize = fs + 'pt';
                // Update margins
                const sm = ss + 'pt';
                const phoneWrap = document.getElementById('covMiniPhoneWrap');
                const sigWrap = document.getElementById('covMiniSigWrap');
                const body = document.getElementById('covMiniBody');
                if (phoneWrap) phoneWrap.style.marginBottom = sm;
                if (body) body.style.marginBottom = sig + 'pt';
                if (sigWrap) sigWrap.style.marginBottom = sm;
                // Sync text from inputs
                const phone = document.getElementById('covPhoneInput')?.value || '2312';
                const refNo = document.getElementById('covRefNoInput')?.value || '49805/HRD/HM/2026';
                const subject = document.getElementById('covSubjectInput')?.value || 'HIRING OF MANPOWER SERVICES';
                const body_tpl = document.getElementById('covBodyInput')?.value || '';
                const sig_name = document.getElementById('covSignatoryInput')?.value || 'Signatory Name';
                const sig_des = document.getElementById('covDesignationInput')?.value || 'Designation';
                const sig_auth = document.getElementById('covAuthorityInput')?.value || 'Authority';
                const recipient = document.getElementById('covRecipientInput')?.value || 'To,\nD-FMM/Purchase';
                if (document.getElementById('covMiniPhone')) document.getElementById('covMiniPhone').textContent = phone;
                if (document.getElementById('covMiniRefNo')) document.getElementById('covMiniRefNo').textContent = refNo;
                if (document.getElementById('covMiniSubject')) document.getElementById('covMiniSubject').textContent = subject;
                if (document.getElementById('covMiniBody')) document.getElementById('covMiniBody').innerHTML = body_tpl.replace(/\{[^}]+\}/g, m => `<b style="color:#94a3b8">${m}</b>`).replace(/\n/g, '<br/>') || document.getElementById('covMiniBody').innerHTML;
                if (document.getElementById('covMiniSignatory')) document.getElementById('covMiniSignatory').textContent = sig_name;
                if (document.getElementById('covMiniDesignation')) document.getElementById('covMiniDesignation').textContent = sig_des;
                if (document.getElementById('covMiniAuthority')) document.getElementById('covMiniAuthority').textContent = sig_auth;
                if (document.getElementById('covMiniRecipient')) document.getElementById('covMiniRecipient').innerHTML = recipient.replace(/\n/g, '<br/>');
            }

            function handleSatHeaderUpload(input) {
                if (input.files && input.files[0]) {
                    const reader = new FileReader();
                    reader.onload = function (e) {
                        const base64Data = e.target.result;
                        document.getElementById('satPreviewHeaderImage').src = base64Data;
                        try {
                            localStorage.setItem('satisfactory_custom_header', base64Data);
                            showToast("Header image uploaded and saved locally.", "success");
                        } catch (err) {
                            showToast("Image too large to persist locally, but preview updated.", "warning");
                        }
                    };
                    reader.readAsDataURL(input.files[0]);
                }
            }

            function downloadSatAsDoc() {
                const sheet = document.getElementById('satisfactoryPrintSheet');
                if (!sheet) { showToast("Certificate preview not loaded.", "error"); return; }

                const imgEl = document.getElementById('satPreviewHeaderImage');
                const headerSrc = imgEl ? imgEl.src : '';
                const txt = id => { const el = document.getElementById(id); return el ? el.textContent : ''; };

                // Read live layout settings
                const docFontSize = parseInt(document.getElementById('satFontSizeInput')?.value) || 14;
                const docSectionSpacing = parseInt(document.getElementById('satSectionSpacingInput')?.value) || 25;
                const docSigSpacing = parseInt(document.getElementById('satSigSpacingInput')?.value) || 50;

                const html = `<html xmlns:o="urn:schemas-microsoft-com:office:office"
xmlns:w="urn:schemas-microsoft-com:office:word"
xmlns="http://www.w3.org/TR/REC-html40">
<head>
<meta charset="UTF-8"/>
<meta name="ProgId" content="Word.Document"/>
<meta name="Generator" content="Microsoft Word 15"/>
<meta name="Originator" content="Microsoft Word 15"/>
<!--[if gte mso 9]><xml>
<w:WordDocument>
  <w:View>Print</w:View>
  <w:Zoom>75</w:Zoom>
  <w:DoNotOptimizeForBrowser/>
</w:WordDocument>
</xml><![endif]-->
<style>
@page Section1 {
  size: 595.3pt 841.9pt;
  margin: 72.0pt 72.0pt 72.0pt 72.0pt;
  mso-header-margin: 36.0pt;
  mso-footer-margin: 36.0pt;
  mso-paper-source: 0;
}
div.Section1 { page: Section1; }
body {
  margin: 0;
  padding: 0;
  font-family: Arial, Helvetica, sans-serif;
  font-size: ${docFontSize}.0pt;
  color: black;
}
p { margin: 0; padding: 0; }
</style>
</head>
<body lang="EN-IN">
<div class="Section1">

<p align="center" style="text-align:center;margin-bottom:${docSectionSpacing}pt;">
<img src="${headerSrc}" width="602" height="142" style="width:451.3pt;height:106.3pt;"/>
</p>

<p align="right" style="text-align:right;margin-bottom:${docSectionSpacing}pt;">
<b>Date: ${txt('satPreviewDate')}</b>
</p>

<p align="center" style="text-align:center;margin-bottom:${docSectionSpacing}pt;">
<b><u>SATISFACTORY CERTIFICATE</u></b>
</p>

<p style="text-align:justify;margin-bottom:${docSectionSpacing}pt;line-height:180%;">${document.getElementById('satParagraph1').innerHTML.trim()}</p>

<p style="text-align:justify;margin-bottom:${docSectionSpacing}pt;line-height:180%;">${document.getElementById('satParagraph2').innerHTML.trim()}</p>

<p style="text-align:justify;margin-bottom:${docSigSpacing}pt;line-height:180%;">${document.getElementById('satParagraph3').innerHTML.trim()}</p>

<table align="right" border="0" cellpadding="0" cellspacing="0" style="margin-top:0; border:none; border-collapse:collapse;">
<tr>
  <td align="center" style="text-align:center; font-family: Arial, Helvetica, sans-serif; font-size:${docFontSize}.0pt; padding:0;">
    <b>${txt('satPreviewSignatory')}</b>
  </td>
</tr>
<tr>
  <td align="center" style="text-align:center; font-family: Arial, Helvetica, sans-serif; font-size:${docFontSize}.0pt; padding:0;">
    ${txt('satPreviewDesignation')}
  </td>
</tr>
</table>
<div style="clear:both;"></div>

</div>
</body>
</html>`;

                const mSel = document.getElementById('satMonth');
                const ySel = document.getElementById('satYear');
                const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                const mName = mSel ? months[parseInt(mSel.value)] : 'Month';
                const yName = ySel ? ySel.value : 'Year';

                const blob = new Blob(['\ufeff', html], { type: 'application/msword' });
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = `Satisfactory_Certificate_${mName}_${yName}.doc`;
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                URL.revokeObjectURL(url);
                showToast("Satisfactory Certificate downloaded as DOC.", "success");
            }

            function resetSatHeaderImage() {
                localStorage.removeItem('satisfactory_custom_header');
                document.getElementById('satPreviewHeaderImage').src = 'Static/images/satisfactory_header.png';
                document.getElementById('satHeaderUploadInput').value = '';
                showToast("Header image reset to default.", "success");
            }

            function formatCategoryText(rawText) {
                if (!rawText || rawText === "All Categories" || rawText === "All") return "All Categories";
                let text = rawText;
                if (text.includes(" > ")) {
                    const parts = text.split(" > ");
                    text = parts[parts.length - 1].trim();
                }
                return text.replace(/\s*\(\s*#.*\)/, "").trim();
            }

            function fillCategoryDropdown(selectElement) {
                if (!selectElement) return;
                selectElement.innerHTML = '<option value="All">All Categories</option>';
                if (categories && categories.length > 0) {
                    categories.forEach(cat => {
                        const parts = cat.split(':');
                        const catVal = parts[0];
                        const rawText = parts.length > 1 ? parts.slice(1).join(':') : cat;
                        const cleanText = formatCategoryText(rawText);
                        selectElement.innerHTML += `<option value="${catVal}">${cleanText}</option>`;
                    });
                }
            }

            function populateSelectors() {
                // Populate Year and Month dropdowns
                const yearSel = document.getElementById("year");
                const monthSel = document.getElementById("month");
                const categorySel = document.getElementById("category");

                const currYear = new Date().getFullYear();
                for (let y = currYear - 2; y <= currYear + 2; y++) {
                    yearSel.innerHTML += `<option value="${y}">${y}</option>`;
                }
                yearSel.value = currYear;

                const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                months.forEach((m, i) => {
                    monthSel.innerHTML += `<option value="${i}">${m}</option>`;
                });
                monthSel.value = new Date().getMonth();

                // Load Categories
                fetch('Documents.aspx/GetCategories', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' }
                })
                    .then(r => r.json())
                    .then(res => {
                        categories = JSON.parse(res.d || "[]");
                        fillCategoryDropdown(document.getElementById("category"));
                        fillCategoryDropdown(document.getElementById("satCategory"));
                        fillCategoryDropdown(document.getElementById("covCategory"));
                        fillCategoryDropdown(document.getElementById("repCategory"));
                        fillWagesCategoryDropdown(document.getElementById("wagesCategory"));
                        onFilterChange();
                        if (typeof onWagesFilterChange === 'function' && document.getElementById("wagesCategory").value) {
                            onWagesFilterChange();
                        }
                        checkUrlParams();
                    })
                    .catch(() => showToast("Failed to load categories.", "error"));
            }

            function checkUrlParams() {
                const urlParams = new URLSearchParams(window.location.search);
                const doc = urlParams.get('doc');
                if (doc === 'wages-calc') {
                    selectDocument('wages-calc', true);

                    const yearVal = urlParams.get('year');
                    const monthVal = urlParams.get('month');
                    const catVal = urlParams.get('category');
                    const wageVal = urlParams.get('wage');
                    const cpIdVal = urlParams.get('contract');

                    if (yearVal) document.getElementById("wagesYear").value = yearVal;
                    if (monthVal) document.getElementById("wagesMonth").value = monthVal;
                    if (catVal) document.getElementById("wagesCategory").value = catVal;
                    if (wageVal) document.getElementById("wagesDailyRate").value = wageVal;

                    if (catVal) {
                        onWagesFilterChange(cpIdVal);
                    }
                }
            }

            function onFilterChange() {
                const yearElem = document.getElementById("year");
                const monthElem = document.getElementById("month");
                const catElem = document.getElementById("category");
                if (!yearElem || !monthElem || !catElem || !yearElem.value || !monthElem.value || !catElem.value) return;
                const yearVal = parseInt(yearElem.value);
                const monthVal = parseInt(monthElem.value);
                const catVal = catElem.value;
                if (isNaN(yearVal) || isNaN(monthVal)) return;

                if (catVal === "All") {
                    document.getElementById("contractGroup").style.display = "none";
                    document.getElementById("contract").innerHTML = "";
                    document.getElementById("vendorName").value = "";
                    document.getElementById("vendorAddress").value = "";
                    document.getElementById("gemContractNo").value = "";
                    document.getElementById("gemContractDate").value = "";
                    updateHeaderPreview();
                    loadData();
                    return;
                }

                // Fetch Contracts
                fetch('Documents.aspx/GetContractsForMonth', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ year: yearVal, month: monthVal, category: catVal })
                })
                    .then(r => r.json())
                    .then(res => {
                        contractsList = JSON.parse(res.d || "[]");
                        const contractSel = document.getElementById("contract");
                        const contractGroup = document.getElementById("contractGroup");

                        if (contractsList.length > 0) {
                            let optionsHtml = "";
                            contractsList.forEach(c => {
                                optionsHtml += `<option value="${c.Id}">${c.DisplayName}</option>`;
                            });
                            contractSel.innerHTML = optionsHtml;
                            contractGroup.style.display = "block";
                            onContractChange();
                        } else {
                            contractGroup.style.display = "none";
                            contractSel.innerHTML = "";
                            document.getElementById("vendorName").value = "";
                            document.getElementById("vendorAddress").value = "";
                            document.getElementById("gemContractNo").value = "";
                            document.getElementById("gemContractDate").value = "";
                            updateHeaderPreview();
                            loadData();
                        }
                    })
                    .catch(() => showToast("Failed to fetch contract periods.", "error"));
            }

            function onContractChange() {
                const contractSel = document.getElementById("contract");
                const selectedId = parseInt(contractSel.value);
                const contract = contractsList.find(c => c.Id === selectedId);

                if (contract) {
                    document.getElementById("vendorName").value = contract.VendorName || "";
                    document.getElementById("vendorAddress").value = contract.VendorAddress || "";
                    document.getElementById("gemContractNo").value = contract.GemId || "";
                    document.getElementById("gemContractDate").value = contract.StartDate || "";
                    document.getElementById("certDatedOnInput").value = contract.VendorDatedOn || "";
                }
                updateHeaderPreview();
                loadData();
            }

            // -- Wages Calculation Javascript Functions --
            let wagesEmployeesData = [];
            let wagesMetadata = null;
            let wagesContractsList = [];

            function fillWagesCategoryDropdown(selectElement) {
                if (!selectElement) return;
                selectElement.innerHTML = "";
                if (categories && categories.length > 0) {
                    categories.forEach(cat => {
                        if (cat !== "All") {
                            const parts = cat.split(':');
                            const catVal = parts[0];
                            const rawText = parts.length > 1 ? parts.slice(1).join(':') : cat;
                            const cleanText = formatCategoryText(rawText);
                            selectElement.innerHTML += `<option value="${catVal}">${cleanText}</option>`;
                        }
                    });
                }
            }

            function populateWagesSelectors(skipFilterChange) {
                const yearSel = document.getElementById("wagesYear");
                const monthSel = document.getElementById("wagesMonth");
                const categorySel = document.getElementById("wagesCategory");

                // Fill Year if empty
                if (yearSel.innerHTML === "") {
                    const currYear = new Date().getFullYear();
                    for (let y = currYear - 2; y <= currYear + 2; y++) {
                        yearSel.innerHTML += `<option value="${y}">${y}</option>`;
                    }
                    yearSel.value = currYear;
                }

                // Fill Month if empty
                if (monthSel.innerHTML === "") {
                    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                    months.forEach((m, i) => {
                        monthSel.innerHTML += `<option value="${i}">${m}</option>`;
                    });
                    monthSel.value = new Date().getMonth();
                }

                // Fill Categories if empty
                if (categorySel.innerHTML === "" || categorySel.options.length === 0) {
                    fillWagesCategoryDropdown(categorySel);
                }

                document.getElementById("wagesServiceChargeRate").value = "3.85";

                if (!skipFilterChange && categorySel.value) {
                    onWagesFilterChange();
                } else {
                    checkWagesAttendanceCompleteness();
                }
            }

            function checkWagesAttendanceCompleteness() {
                const yearEl = document.getElementById("wagesYear");
                const monthEl = document.getElementById("wagesMonth");
                if (!yearEl || !monthEl || yearEl.value === "" || monthEl.value === "") return;

                const yearVal = parseInt(yearEl.value);
                const monthVal = parseInt(monthEl.value);
                const catVal = document.getElementById("wagesCategory") ? document.getElementById("wagesCategory").value : "";
                const contractSel = document.getElementById("wagesContract");
                const cpId = (contractSel && contractSel.value && contractSel.value !== "") ? parseInt(contractSel.value) : null;

                fetch('Documents.aspx/CheckAttendanceCompleteness', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ year: yearVal, month: monthVal, category: catVal, contractPeriodId: cpId })
                })
                    .then(r => r.json())
                    .then(res => {
                        const data = JSON.parse(res.d || "{}");
                        const warnEl = document.getElementById("wagesAttendanceWarning");
                        if (!warnEl) return;

                        if (data.HasIncomplete) {
                            const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
                            const monthName = months[monthVal] || "";
                            document.getElementById("wagesWarningTitle").textContent = `Attendance Warning: Incomplete Records for ${monthName} ${yearVal}`;

                            let html = '<ul style="margin: 0; padding-left: 20px; list-style-type: disc;">';
                            if (data.MissingCount > 0) {
                                const eg = (data.MissingExamples && data.MissingExamples.length) ? ` <span style="font-size:0.8rem; color:#92400e;">(e.g. ${data.MissingExamples.join(', ')})</span>` : '';
                                html += `<li><strong>${data.MissingCount} day(s)</strong> have no attendance entered${eg}.</li>`;
                            }
                            if (data.UnspecifiedZeroCount > 0) {
                                const eg = (data.UnspecifiedZeroExamples && data.UnspecifiedZeroExamples.length) ? ` <span style="font-size:0.8rem; color:#92400e;">(e.g. ${data.UnspecifiedZeroExamples.join(', ')})</span>` : '';
                                html += `<li><strong>${data.UnspecifiedZeroCount} absent (0) day(s)</strong> have neither Paid nor Unpaid specified${eg}.</li>`;
                            }
                            if (data.PendingPairingCount > 0) {
                                const eg = (data.PendingPairingExamples && data.PendingPairingExamples.length) ? ` <span style="font-size:0.8rem; color:#92400e;">(e.g. ${data.PendingPairingExamples.join(', ')})</span>` : '';
                                html += `<li><strong>${data.PendingPairingCount} half-day pairing(s)</strong> are pending classification (not marked as Paired Paid or Paired Unpaid)${eg}.</li>`;
                            }
                            html += '</ul>';
                            document.getElementById("wagesWarningDetails").innerHTML = html;
                            warnEl.style.display = "block";
                        } else {
                            warnEl.style.display = "none";
                        }
                    })
                    .catch(err => {
                        console.error("Error checking wages attendance completeness:", err);
                    });
            }

            function onWagesFilterChange(selectedContractId) {
                checkWagesAttendanceCompleteness();

                const yearVal = parseInt(document.getElementById("wagesYear").value);
                const monthVal = parseInt(document.getElementById("wagesMonth").value);
                const catVal = document.getElementById("wagesCategory").value;

                if (!catVal || catVal === "All") {
                    document.getElementById("wagesContractGroup").style.display = "none";
                    document.getElementById("wagesContract").innerHTML = "";
                    resetWagesHeader();
                    return;
                }

                // Fetch Contracts
                fetch('Documents.aspx/GetContractsForMonth', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ year: yearVal, month: monthVal, category: catVal })
                })
                    .then(r => r.json())
                    .then(res => {
                        wagesContractsList = JSON.parse(res.d || "[]");
                        const contractSel = document.getElementById("wagesContract");
                        const contractGroup = document.getElementById("wagesContractGroup");

                        if (wagesContractsList.length > 0) {
                            let optionsHtml = "";
                            wagesContractsList.forEach(c => {
                                optionsHtml += `<option value="${c.Id}">${c.DisplayName}</option>`;
                            });
                            contractSel.innerHTML = optionsHtml;
                            contractGroup.style.display = "block";

                            if (selectedContractId && wagesContractsList.some(c => c.Id === parseInt(selectedContractId))) {
                                contractSel.value = selectedContractId;
                            }

                            onWagesContractChange();
                        } else {
                            contractGroup.style.display = "none";
                            contractSel.innerHTML = "";
                            resetWagesHeader();
                        }
                    })
                    .catch(() => showToast("Failed to fetch contract periods.", "error"));
            }

            function onWagesContractChange() {
                checkWagesAttendanceCompleteness();
                const contractSel = document.getElementById("wagesContract");
                const selectedId = parseInt(contractSel.value);
                const contract = wagesContractsList.find(c => c.Id === selectedId);

                if (contract) {
                    loadWagesData();
                } else {
                    resetWagesHeader();
                }
            }

            function resetWagesHeader() {
                document.getElementById("wagesHeaderContract").innerHTML = "Contract No. [Contract No] Dt. [Contract Date]";
                document.getElementById("wagesHeaderCategory").innerHTML = "Manpower Services - [Category Name] - [People Count] No.s";
                document.getElementById("wagesHeaderPeriod").innerHTML = "Contract Period [Start Date] to [End Date]";
                document.getElementById("wagesHeaderVendor").innerHTML = "[Vendor Name], [Vendor Address]";
                document.getElementById("wagesHeaderPayment").innerHTML = "Payment for the period [Start Date] to [End Date]";

                document.getElementById("wagesContractNoInput").value = "";
                document.getElementById("wagesContractDateInput").value = "";
                document.getElementById("wagesDatedOnInput").value = "";
                document.getElementById("wagesCategoryDescInput").value = "";
                document.getElementById("wagesPeriodInput").value = "";
                document.getElementById("wagesVendorNameInput").value = "";
                document.getElementById("wagesVendorAddressInput").value = "";

                document.getElementById("wagesTableBody").innerHTML = "";
                document.getElementById("wagesTotalPeople").textContent = "0";
                document.getElementById("wagesTotalDays").textContent = "0";
                document.getElementById("wagesPreviewArea").style.display = "none";
                window.wagesAltScEnabled = false;
                window.wagesAltScData = null;
                const badge = document.getElementById("wagesAltScBadge");
                if (badge) badge.style.display = "none";
                const notice = document.getElementById("wagesAltScStatusNotice");
                if (notice) notice.style.display = "none";
                const chk = document.getElementById("chkUseAltServiceCharge");
                if (chk) chk.checked = false;
                const banner = document.getElementById("wagesAltAppliedBanner");
                if (banner) banner.style.display = "none";
                const altDailyRateInput = document.getElementById("wagesAltDailyRate");
                if (altDailyRateInput) altDailyRateInput.value = "";
                calculateAltServiceCharge();
            }

            function loadWagesData() {
                const loader = document.getElementById("wagesLoader");
                const previewArea = document.getElementById("wagesPreviewArea");
                const yearVal = parseInt(document.getElementById("wagesYear").value);
                const monthVal = parseInt(document.getElementById("wagesMonth").value);
                const catVal = document.getElementById("wagesCategory").value;
                const contractSel = document.getElementById("wagesContract");
                const selectedCpId = contractSel && contractSel.value ? parseInt(contractSel.value) : null;

                if (!catVal || catVal === "All" || !selectedCpId) {
                    showToast("Please select a Category and Contract Period.", "warning");
                    return;
                }

                loader.style.display = "block";
                previewArea.style.display = "none";

                Promise.all([
                    fetch('Documents.aspx/GetWagesMetadata', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ year: yearVal, month: monthVal, category: catVal, contractPeriodId: selectedCpId })
                    }).then(r => r.json()),

                    fetch('Documents.aspx/GetCertificateData', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ year: yearVal, month: monthVal, category: catVal, contractPeriodId: selectedCpId })
                    }).then(r => r.json())
                ])
                    .then(([metaRes, empRes]) => {
                        wagesMetadata = JSON.parse(metaRes.d || "{}");
                        wagesEmployeesData = JSON.parse(empRes.d || "[]");

                        if (wagesEmployeesData.error) {
                            showToast(wagesEmployeesData.error, "error");
                            loader.style.display = "none";
                            return;
                        }

                        if (wagesMetadata.DailyWage > 0) {
                            document.getElementById("wagesDailyRate").value = wagesMetadata.DailyWage;
                        } else {
                            document.getElementById("wagesDailyRate").value = "";
                        }

                        if (wagesMetadata.EpfRate !== undefined && wagesMetadata.EpfRate !== null) {
                            document.getElementById("wagesEpfRate").value = wagesMetadata.EpfRate;
                        }
                        if (wagesMetadata.EpfLimit !== undefined && wagesMetadata.EpfLimit !== null) {
                            document.getElementById("wagesEpfLimit").value = wagesMetadata.EpfLimit;
                        }
                        if (wagesMetadata.EpfCappedAmount !== undefined && wagesMetadata.EpfCappedAmount !== null) {
                            document.getElementById("wagesEpfCappedAmount").value = wagesMetadata.EpfCappedAmount;
                        }
                        if (wagesMetadata.GstRate !== undefined && wagesMetadata.GstRate !== null) {
                            document.getElementById("wagesGstRate").value = wagesMetadata.GstRate;
                        }

                        // Prefill editable fields
                        if (wagesMetadata && wagesMetadata.Contract) {
                            const contract = wagesMetadata.Contract;
                            document.getElementById("wagesContractNoInput").value = contract.GemId || "";
                            document.getElementById("wagesContractDateInput").value = contract.StartDate || "";
                            document.getElementById("wagesDatedOnInput").value = contract.VendorDatedOn || "";
                            const catInfo = getSelectedCategoryInfo(document.getElementById("wagesCategory"));
                            const catName = catInfo.cleanName;
                            const customDesc = wagesCategoryDescriptions[catVal] || wagesCategoryDescriptions[catName] || `Data Entry Operators(${catName})`;
                            document.getElementById("wagesCategoryDescInput").value = customDesc;
                            document.getElementById("wagesPeriodInput").value = contract.EndDate ? `${contract.StartDate} to ${contract.EndDate}` : `${contract.StartDate} onwards`;
                            document.getElementById("wagesVendorNameInput").value = contract.VendorName || "";
                            document.getElementById("wagesVendorAddressInput").value = contract.VendorAddress || "";
                        }

                        // Check if Alternate Service Charge was previously saved and applied for this matching period
                        const altBanner = document.getElementById("wagesAltAppliedBanner");
                        const altMetaText = document.getElementById("wagesAltAppliedMetaText");
                        const altDailyRateInput = document.getElementById("wagesAltDailyRate");

                        if (wagesMetadata && wagesMetadata.AlternateService) {
                            const alt = wagesMetadata.AlternateService;
                            if (alt.DailyRate > 0 && altDailyRateInput) {
                                altDailyRateInput.value = alt.DailyRate;
                            }
                            if (alt.ScRate) {
                                const scEl = document.getElementById("wagesAltScRate");
                                if (scEl) { scEl.value = alt.ScRate; scEl.dataset.userEdited = "true"; }
                            }
                            if (alt.EpfRate) {
                                const epfEl = document.getElementById("wagesAltEpfRate");
                                if (epfEl) { epfEl.value = alt.EpfRate; epfEl.dataset.userEdited = "true"; }
                            }
                            if (alt.EpfLimit) {
                                const limitEl = document.getElementById("wagesAltEpfLimit");
                                if (limitEl) { limitEl.value = alt.EpfLimit; limitEl.dataset.userEdited = "true"; }
                            }
                            if (alt.EpfCappedAmount) {
                                const capEl = document.getElementById("wagesAltEpfCappedAmount");
                                if (capEl) { capEl.value = alt.EpfCappedAmount; capEl.dataset.manualOverride = "true"; }
                            }

                            // Calculate with loaded employee data
                            calculateAltServiceCharge();

                            if (alt.IsApplied && alt.DailyRate > 0) {
                                window.wagesAltScEnabled = true;
                                const chk = document.getElementById("chkUseAltServiceCharge");
                                if (chk) chk.checked = true;

                                if (altBanner) {
                                    altBanner.style.display = "block";
                                    if (altMetaText) {
                                        const dateStr = alt.UpdatedAt ? ` on ${alt.UpdatedAt}` : "";
                                        const byStr = alt.UpdatedBy ? ` by ${alt.UpdatedBy}` : "";
                                        altMetaText.textContent = `Applied at Rs. ${alt.DailyRate}/day (Saved${byStr}${dateStr}).`;
                                    }
                                }
                            } else {
                                window.wagesAltScEnabled = false;
                                const chk = document.getElementById("chkUseAltServiceCharge");
                                if (chk) chk.checked = false;
                                if (altBanner) altBanner.style.display = "none";
                            }
                        } else {
                            if (altDailyRateInput) altDailyRateInput.value = "";
                            window.wagesAltScEnabled = false;
                            const chk = document.getElementById("chkUseAltServiceCharge");
                            if (chk) chk.checked = false;
                            if (altBanner) altBanner.style.display = "none";
                            syncAltWagesDrawerWithLoadedData();
                        }

                        updateWagesPreview();
                        loader.style.display = "none";
                        previewArea.style.display = "block";
                        if (window.wagesAltScEnabled && window.wagesAltScData) {
                            showToast(`Loaded wages calculation (Alternate Service Charge Applied: Rs. ${window.wagesAltScData.serviceCharge.toFixed(2)})`, "success");
                        } else {
                            showToast(`Loaded wages calculation data successfully!`, "success");
                        }
                    })
                    .catch((err) => {
                        console.error(err);
                        loader.style.display = "none";
                        showToast("Failed to retrieve wages calculation data.", "error");
                    });
            }

            function updateWagesPreview() {
                if (!wagesEmployeesData || wagesEmployeesData.length === 0) return;

                const dailyRate = parseFloat(document.getElementById("wagesDailyRate").value) || 0;
                const epfRate = parseFloat(document.getElementById("wagesEpfRate").value) || 0;
                const epfLimit = parseFloat(document.getElementById("wagesEpfLimit").value) || 0;
                const serviceChargeRate = parseFloat(document.getElementById("wagesServiceChargeRate").value) || 0;
                const gstRate = parseFloat(document.getElementById("wagesGstRate").value) || 0;

                const epfMaxAmount = parseFloat(document.getElementById("wagesEpfCappedAmount").value) || 0;

                // Group employees by FinalDays
                const groups = {};
                wagesEmployeesData.forEach(emp => {
                    const days = emp.FinalDays;
                    groups[days] = (groups[days] || 0) + 1;
                });

                // Sort days descending
                const sortedDays = Object.keys(groups).map(Number).sort((a, b) => b - a);

                let bodyHtml = "";
                let slNo = 1;
                let totalPeople = 0;
                let totalWorkingDays = 0;
                let epfCappedCount = 0;
                let epfActualCount = 0;
                let epfActualSum = 0;
                let isFirstRow = true;

                sortedDays.forEach(days => {
                    const peopleCount = groups[days];
                    const paymentPerPerson = days * dailyRate;
                    const rowTotalDays = peopleCount * days;

                    totalPeople += peopleCount;
                    totalWorkingDays += rowTotalDays;

                    // EPF Capping calculation
                    if (paymentPerPerson >= epfLimit) {
                        epfCappedCount += peopleCount;
                    } else {
                        epfActualCount += peopleCount;
                        epfActualSum += (paymentPerPerson * (epfRate / 100)) * peopleCount;
                    }

                    bodyHtml += `
                    <tr>
                        <td style="border: 1px solid #000000; padding: 8px; text-align: center;">${slNo++}</td>
                        <td style="border: 1px solid #000000; padding: 8px; text-align: left;">${isFirstRow ? dailyRate.toFixed(2) : ''}</td>
                        <td style="border: 1px solid #000000; padding: 8px; text-align: right;">${paymentPerPerson.toFixed(2)}</td>
                        <td style="border: 1px solid #000000; padding: 8px; text-align: center;">${peopleCount}</td>
                        <td style="border: 1px solid #000000; padding: 8px; text-align: center;">${days}</td>
                        <td style="border: 1px solid #000000; padding: 8px; text-align: right;">${rowTotalDays}</td>
                    </tr>
                `;
                    isFirstRow = false;
                });

                document.getElementById("wagesTableBody").innerHTML = bodyHtml;
                document.getElementById("wagesTotalPeople").textContent = totalPeople;
                document.getElementById("wagesTotalDays").textContent = totalWorkingDays;

                // Update dynamically generated Col C header with daily rate
                document.getElementById("wagesColCHeader").textContent = `Payment per person/per month Rs${dailyRate.toFixed(2)}/-PD`;

                // Calculations breakdown
                const wagesTotal = totalWorkingDays * dailyRate;
                const epfCappedTotal = epfCappedCount * epfMaxAmount;
                const subTotal = wagesTotal + epfCappedTotal + epfActualSum;

                // Determine Service Charge: Standard or Alternate
                const standardServiceCharge = subTotal * (serviceChargeRate / 100);
                let serviceCharge = standardServiceCharge;
                let scFormulaText = `Service Charge  @${serviceChargeRate.toFixed(2)}% `;

                const badge = document.getElementById("wagesAltScBadge");
                const notice = document.getElementById("wagesAltScStatusNotice");
                const appliedAmountEl = document.getElementById("wagesAltScAppliedAmount");
                const chk = document.getElementById("chkUseAltServiceCharge");

                if (window.wagesAltScEnabled && window.wagesAltScData && window.wagesAltScData.serviceCharge > 0) {
                    serviceCharge = window.wagesAltScData.serviceCharge;
                    scFormulaText = `Service Charge  @${window.wagesAltScData.scRate.toFixed(2)}% `;
                    if (badge) badge.style.display = "inline-block";
                    if (notice) notice.style.display = "block";
                    if (appliedAmountEl) appliedAmountEl.textContent = serviceCharge.toFixed(2);
                    if (chk) chk.checked = true;
                } else {
                    if (badge) badge.style.display = "none";
                    if (notice) notice.style.display = "none";
                    if (chk) chk.checked = false;
                }

                const gst = subTotal * (gstRate / 100);
                const grandTotal = subTotal + serviceCharge + gst;

                // Set breakdown values on screen
                document.getElementById("wagesFormulaDesc").textContent = `${dailyRate}*${totalWorkingDays}`;
                document.getElementById("wagesAmountWages").textContent = wagesTotal.toFixed(2);

                document.getElementById("wagesFormulaEpfCapped").textContent = `EPF @${epfRate}%for ${epfCappedCount} persons`;
                document.getElementById("wagesAmountEpfCapped").textContent = epfCappedTotal.toFixed(2);

                document.getElementById("wagesFormulaEpfActual").textContent = `EPF @${epfRate}%for ${epfActualCount} person`;
                document.getElementById("wagesAmountEpfActual").textContent = epfActualSum.toFixed(2);

                document.getElementById("wagesAmountSubTotal").textContent = subTotal.toFixed(2);

                document.getElementById("wagesFormulaServiceCharge").textContent = scFormulaText;
                document.getElementById("wagesAmountServiceCharge").textContent = serviceCharge.toFixed(2);

                document.getElementById("wagesFormulaGst").textContent = `GST @${gstRate.toFixed(2)}%`;
                document.getElementById("wagesAmountGst").textContent = gst.toFixed(2);

                document.getElementById("wagesAmountGrandTotal").textContent = grandTotal.toFixed(2);

                // Break-up calculation based on the Basic Daily Wage Rate
                const epfDaily = (epfLimit * 0.12) / 26;
                const edliDaily = (epfLimit * 0.005) / 26;
                const adminDaily = (epfLimit * 0.005) / 26;
                const grossDaily = dailyRate + epfDaily + edliDaily + adminDaily;

                const categoryVal = document.getElementById("wagesCategory").value;
                window.wagesBreakupData = {
                    title: "VALUE AS PER GOVT VALUE",
                    category: `DEO (${categoryVal})`,
                    basic: dailyRate,
                    epf: epfDaily,
                    epfDesc: "EPF @ 12% of Basic Wages",
                    edli: edliDaily,
                    edliDesc: "EPF ELDI @ 0.5% of Basic Wages",
                    admin: adminDaily,
                    adminDesc: "EPF Admin @ 0.5% of Basic Wages",
                    gross: grossDaily
                };

                // Update header text previews from config panel inputs (with fallback placeholders)
                const contractNo = document.getElementById("wagesContractNoInput").value || "[Contract No]";
                const contractDate = document.getElementById("wagesContractDateInput").value || "[Contract Date]";
                const extraCode = document.getElementById("wagesExtraCodeInput").value || "";
                const categoryDesc = document.getElementById("wagesCategoryDescInput").value || "[Category Description]";
                const periodVal = document.getElementById("wagesPeriodInput").value || "[Start Date] to [End Date]";
                const vendorName = document.getElementById("wagesVendorNameInput").value || "[Vendor Name]";
                const vendorAddress = document.getElementById("wagesVendorAddressInput").value || "[Vendor Address]";
                const wagesDatedOn = document.getElementById("wagesDatedOnInput").value || "[Dated On]";

                const yValSelect = document.getElementById("wagesYear");
                if (!yValSelect || !yValSelect.value) return;
                const yVal = yValSelect.value;

                const mSelect = document.getElementById("wagesMonth");
                if (!mSelect || mSelect.selectedIndex === -1) return;
                const mText = mSelect.options[mSelect.selectedIndex].text;

                const daysInMonth = new Date(parseInt(yVal), parseInt(mSelect.value) + 1, 0).getDate();

                // Working days excluding Sundays in the month of payment
                let workingDaysExcludingSundays = 0;
                for (let d = 1; d <= daysInMonth; d++) {
                    const dayOfWeek = new Date(parseInt(yVal), parseInt(mSelect.value), d).getDay();
                    if (dayOfWeek !== 0) { // 0 = Sunday
                        workingDaysExcludingSundays++;
                    }
                }

                // Substitute placeholders in loaded templates
                const tpl1 = document.getElementById("txtWagesTplContract").value;
                const tpl2 = document.getElementById("txtWagesTplCategory").value;
                const tpl3 = document.getElementById("txtWagesTplPeriod").value;
                const tpl4 = document.getElementById("txtWagesTplVendor").value;
                const tpl5 = document.getElementById("txtWagesTplPayment").value;

                const paymentStart = `01 ${mText} ${yVal}`;
                const paymentEnd = `${daysInMonth} ${mText} ${yVal}`;

                const line1Html = replacePlaceholders(tpl1, "wages");
                const line2Html = replacePlaceholders(tpl2, "wages");
                const line3Html = replacePlaceholders(tpl3, "wages");
                const line4Html = replacePlaceholders(tpl4, "wages");
                const line5Html = replacePlaceholders(tpl5, "wages");

                document.getElementById("wagesHeaderContract").innerHTML = line1Html;
                document.getElementById("wagesHeaderCategory").innerHTML = line2Html;
                document.getElementById("wagesHeaderPeriod").innerHTML = line3Html;
                document.getElementById("wagesHeaderVendor").innerHTML = line4Html;
                document.getElementById("wagesHeaderPayment").innerHTML = line5Html;
            }

            // -- Alternate Service Charge Calculations & Drawer Controller --
            window.wagesAltScEnabled = false;
            window.wagesAltScData = null;

            function toggleWagesAltDrawer() {
                const drawer = document.getElementById("wagesAltServiceChargeDrawer");
                const overlay = document.getElementById("wagesAltDrawerOverlay");
                if (drawer && overlay) {
                    if (drawer.classList.contains("open")) {
                        closeWagesAltDrawer();
                    } else {
                        closePlaceholdersDrawer();
                        syncAltWagesDrawerWithLoadedData();
                        drawer.classList.add("open");
                        overlay.style.display = "block";
                        const rateInput = document.getElementById("wagesAltDailyRate");
                        if (rateInput && !rateInput.value) {
                            setTimeout(() => rateInput.focus(), 250);
                        }
                    }
                }
            }

            function closeWagesAltDrawer() {
                const drawer = document.getElementById("wagesAltServiceChargeDrawer");
                const overlay = document.getElementById("wagesAltDrawerOverlay");
                if (drawer && overlay) {
                    drawer.classList.remove("open");
                    overlay.style.display = "none";
                }
            }

            function syncAltWagesDrawerWithLoadedData() {
                const scRateInput = document.getElementById("wagesServiceChargeRate");
                const epfRateInput = document.getElementById("wagesEpfRate");
                const epfLimitInput = document.getElementById("wagesEpfLimit");
                const epfCappedInput = document.getElementById("wagesEpfCappedAmount");

                const altScRate = document.getElementById("wagesAltScRate");
                const altEpfRate = document.getElementById("wagesAltEpfRate");
                const altEpfLimit = document.getElementById("wagesAltEpfLimit");
                const altEpfCapped = document.getElementById("wagesAltEpfCappedAmount");

                if (altScRate && (!altScRate.value || altScRate.dataset.userEdited !== "true")) {
                    altScRate.value = scRateInput && scRateInput.value ? scRateInput.value : "3.85";
                }
                if (altEpfRate && (!altEpfRate.value || altEpfRate.dataset.userEdited !== "true")) {
                    altEpfRate.value = epfRateInput && epfRateInput.value ? epfRateInput.value : "13";
                }
                if (altEpfLimit && (!altEpfLimit.value || altEpfLimit.dataset.userEdited !== "true")) {
                    altEpfLimit.value = epfLimitInput && epfLimitInput.value ? epfLimitInput.value : "15000";
                }
                if (altEpfCapped && (!altEpfCapped.value || altEpfCapped.dataset.manualOverride !== "true")) {
                    altEpfCapped.value = epfCappedInput && epfCappedInput.value ? epfCappedInput.value : "1950";
                }

                calculateAltServiceCharge();
            }

            function resetAltDrawerToMainDefaults() {
                const scRateInput = document.getElementById("wagesServiceChargeRate");
                const epfRateInput = document.getElementById("wagesEpfRate");
                const epfLimitInput = document.getElementById("wagesEpfLimit");
                const epfCappedInput = document.getElementById("wagesEpfCappedAmount");

                const altScRate = document.getElementById("wagesAltScRate");
                const altEpfRate = document.getElementById("wagesAltEpfRate");
                const altEpfLimit = document.getElementById("wagesAltEpfLimit");
                const altEpfCapped = document.getElementById("wagesAltEpfCappedAmount");

                if (altScRate) {
                    altScRate.value = scRateInput && scRateInput.value ? scRateInput.value : "3.85";
                    delete altScRate.dataset.userEdited;
                }
                if (altEpfRate) {
                    altEpfRate.value = epfRateInput && epfRateInput.value ? epfRateInput.value : "13";
                    delete altEpfRate.dataset.userEdited;
                }
                if (altEpfLimit) {
                    altEpfLimit.value = epfLimitInput && epfLimitInput.value ? epfLimitInput.value : "15000";
                    delete altEpfLimit.dataset.userEdited;
                }
                if (altEpfCapped) {
                    altEpfCapped.value = epfCappedInput && epfCappedInput.value ? epfCappedInput.value : "1950";
                    delete altEpfCapped.dataset.manualOverride;
                }
                calculateAltServiceCharge();
                if (typeof showToast === "function") {
                    showToast("Parameters reset to main defaults.", "info");
                }
            }

            function onAltEpfParamsChange() {
                const limit = parseFloat(document.getElementById("wagesAltEpfLimit").value) || 0;
                const rate = parseFloat(document.getElementById("wagesAltEpfRate").value) || 0;
                const cappedInput = document.getElementById("wagesAltEpfCappedAmount");
                if (cappedInput && cappedInput.dataset.manualOverride !== "true") {
                    cappedInput.value = Math.round(limit * (rate / 100));
                }
                calculateAltServiceCharge();
            }

            function calculateAltServiceCharge() {
                const noDataEl = document.getElementById("wagesAltNoDataNotice");
                const dataContainerEl = document.getElementById("wagesAltDataContainer");

                if (!wagesEmployeesData || wagesEmployeesData.length === 0) {
                    if (noDataEl) {
                        noDataEl.style.display = "block";
                        noDataEl.innerHTML = '<i class="fas fa-exclamation-circle fa-2x mb-2 d-block" style="color: #cbd5e1;"></i>Please load wages data first using the "Load Data" button.';
                    }
                    if (dataContainerEl) dataContainerEl.style.display = "none";
                    window.wagesAltScData = null;
                    return;
                }

                const altDailyRate = parseFloat(document.getElementById("wagesAltDailyRate").value) || 0;
                const altScRate = parseFloat(document.getElementById("wagesAltScRate").value) || 0;
                const altEpfRate = parseFloat(document.getElementById("wagesAltEpfRate").value) || 0;
                const altEpfLimit = parseFloat(document.getElementById("wagesAltEpfLimit").value) || 0;
                const altEpfCappedAmount = parseFloat(document.getElementById("wagesAltEpfCappedAmount").value) || 0;

                if (altDailyRate <= 0) {
                    if (noDataEl) {
                        noDataEl.style.display = "block";
                        noDataEl.innerHTML = '<i class="fas fa-coins fa-2x mb-2 d-block" style="color: #f59e0b;"></i>Enter amount for each day above to calculate alternate service charge.';
                    }
                    if (dataContainerEl) dataContainerEl.style.display = "none";
                    window.wagesAltScData = null;
                    return;
                }

                // Employees grouped by FinalDays
                const groups = {};
                wagesEmployeesData.forEach(emp => {
                    const days = emp.FinalDays;
                    groups[days] = (groups[days] || 0) + 1;
                });

                const sortedDays = Object.keys(groups).map(Number).sort((a, b) => b - a);

                let totalPeople = 0;
                let totalWorkingDays = 0;
                let epfCappedCount = 0;
                let epfActualCount = 0;
                let epfActualSum = 0;
                let tableRowsHtml = "";

                sortedDays.forEach(days => {
                    const peopleCount = groups[days];
                    const paymentPerPerson = days * altDailyRate;
                    const rowTotalDays = peopleCount * days;

                    totalPeople += peopleCount;
                    totalWorkingDays += rowTotalDays;

                    let epfType = "";
                    if (paymentPerPerson >= altEpfLimit) {
                        epfCappedCount += peopleCount;
                        epfType = `<span class="badge badge-info" style="font-size:0.68rem; background:#e0f2fe; color:#0369a1; padding:2px 5px; border-radius:4px;">Capped (${altEpfCappedAmount})</span>`;
                    } else {
                        epfActualCount += peopleCount;
                        const rowActual = (paymentPerPerson * (altEpfRate / 100)) * peopleCount;
                        epfActualSum += rowActual;
                        epfType = `<span class="badge badge-secondary" style="font-size:0.68rem; background:#f1f5f9; color:#475569; padding:2px 5px; border-radius:4px;">Actual (${(paymentPerPerson * (altEpfRate / 100)).toFixed(2)})</span>`;
                    }

                    tableRowsHtml += `
                        <tr style="border-bottom: 1px solid #f1f5f9;">
                            <td style="padding: 4px; text-align: center;">${days}</td>
                            <td style="padding: 4px; text-align: center;">${peopleCount}</td>
                            <td style="padding: 4px; text-align: right;">${rowTotalDays}</td>
                            <td style="padding: 4px; text-align: right;">${paymentPerPerson.toFixed(2)}</td>
                            <td style="padding: 4px; text-align: center;">${epfType}</td>
                        </tr>
                    `;
                });

                const altWagesTotal = totalWorkingDays * altDailyRate;
                const altEpfCappedTotal = epfCappedCount * altEpfCappedAmount;
                const altSubTotal = altWagesTotal + altEpfCappedTotal + epfActualSum;
                const altServiceCharge = altSubTotal * (altScRate / 100);

                const catSelect = document.getElementById("wagesCategory");
                const catName = catSelect && catSelect.options && catSelect.selectedIndex >= 0 ? catSelect.options[catSelect.selectedIndex].text : "Selected Category";

                // Save calculation result object
                window.wagesAltScData = {
                    dailyRate: altDailyRate,
                    scRate: altScRate,
                    epfRate: altEpfRate,
                    epfLimit: altEpfLimit,
                    epfCappedAmount: altEpfCappedAmount,
                    totalPeople: totalPeople,
                    totalWorkingDays: totalWorkingDays,
                    wagesTotal: altWagesTotal,
                    epfCappedCount: epfCappedCount,
                    epfCappedTotal: altEpfCappedTotal,
                    epfActualCount: epfActualCount,
                    epfActualSum: epfActualSum,
                    subTotal: altSubTotal,
                    serviceCharge: altServiceCharge
                };

                // Update UI elements in drawer
                if (noDataEl) noDataEl.style.display = "none";
                if (dataContainerEl) dataContainerEl.style.display = "block";

                document.getElementById("wagesAltCatName").textContent = catName;
                document.getElementById("wagesAltPeopleCount").textContent = totalPeople;
                document.getElementById("wagesAltTotalDays").textContent = totalWorkingDays;
                document.getElementById("wagesAltWagesFormula").textContent = `${altDailyRate}*${totalWorkingDays}`;
                document.getElementById("wagesAltWagesTotal").textContent = "Rs. " + altWagesTotal.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
                document.getElementById("wagesAltEpfCappedLabel").textContent = `EPF @${altEpfRate}% (${epfCappedCount} persons capped):`;
                document.getElementById("wagesAltEpfCappedTotal").textContent = "Rs. " + altEpfCappedTotal.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
                document.getElementById("wagesAltEpfActualLabel").textContent = `EPF @${altEpfRate}% (${epfActualCount} persons actual):`;
                document.getElementById("wagesAltEpfActualTotal").textContent = "Rs. " + epfActualSum.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
                document.getElementById("wagesAltSubTotal").textContent = "Rs. " + altSubTotal.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 });

                document.getElementById("wagesAltGeneratedScAmount").textContent = "Rs. " + altServiceCharge.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
                document.getElementById("wagesAltScRateFormula").textContent = `@ ${altScRate.toFixed(2)}% of Alternate Sub Total (Rs. ${altSubTotal.toFixed(2)})`;

                const tableBody = document.getElementById("altGroupTableBody");
                if (tableBody) tableBody.innerHTML = tableRowsHtml;

                // If currently enabled on the main bill, update the main bill in real time
                if (window.wagesAltScEnabled) {
                    updateWagesPreview();
                }
            }

            function saveWagesAltServiceChargeToServer(isApplied, callback) {
                const yearVal = parseInt(document.getElementById("wagesYear").value);
                const monthVal = parseInt(document.getElementById("wagesMonth").value);
                const catVal = document.getElementById("wagesCategory").value;
                const contractSel = document.getElementById("wagesContract");
                const selectedCpId = contractSel && contractSel.value ? parseInt(contractSel.value) : null;

                if (!catVal || catVal === "All" || !selectedCpId) {
                    if (callback) callback(false);
                    return;
                }

                const altDailyRate = parseFloat(document.getElementById("wagesAltDailyRate").value) || 0;
                const altScRate = parseFloat(document.getElementById("wagesAltScRate").value) || 3.85;
                const altEpfRate = parseFloat(document.getElementById("wagesAltEpfRate").value) || 13;
                const altEpfLimit = parseFloat(document.getElementById("wagesAltEpfLimit").value) || 15000;
                const altEpfCappedAmount = parseFloat(document.getElementById("wagesAltEpfCappedAmount").value) || 1950;
                const serviceCharge = window.wagesAltScData ? window.wagesAltScData.serviceCharge : 0;

                fetch('Documents.aspx/SaveWagesAlternateServiceCharge', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        year: yearVal,
                        month: monthVal,
                        category: catVal,
                        contractPeriodId: selectedCpId,
                        dailyRate: altDailyRate,
                        scRate: altScRate,
                        epfRate: altEpfRate,
                        epfLimit: altEpfLimit,
                        epfCappedAmount: altEpfCappedAmount,
                        serviceCharge: serviceCharge,
                        isApplied: isApplied
                    })
                })
                .then(r => r.json())
                .then(res => {
                    const data = JSON.parse(res.d || "{}");
                    if (data.status === "error") {
                        showToast(data.message || "Failed to save alternate service charge.", "error");
                        if (callback) callback(false);
                    } else {
                        if (callback) callback(true);
                    }
                })
                .catch(err => {
                    console.error(err);
                    showToast("Network error while saving alternate service charge.", "error");
                    if (callback) callback(false);
                });
            }

            function applyAltServiceChargeToMain() {
                if (!window.wagesAltScData || window.wagesAltScData.dailyRate <= 0) {
                    showToast("Please enter a valid amount for each day first.", "warning");
                    return;
                }
                window.wagesAltScEnabled = true;
                const chk = document.getElementById("chkUseAltServiceCharge");
                if (chk) chk.checked = true;
                const altBanner = document.getElementById("wagesAltAppliedBanner");
                if (altBanner) {
                    altBanner.style.display = "block";
                    const altMetaText = document.getElementById("wagesAltAppliedMetaText");
                    if (altMetaText) {
                        altMetaText.textContent = `Applied at Rs. ${window.wagesAltScData.dailyRate}/day (Saved).`;
                    }
                }
                updateWagesPreview();

                // Save to server
                saveWagesAltServiceChargeToServer(true, function(success) {
                    if (success) {
                        showToast(`Saved and applied alternate service charge (Rs. ${window.wagesAltScData.serviceCharge.toFixed(2)}) to main bill!`, "success");
                    }
                });

                closeWagesAltDrawer();
            }

            function revertToStandardServiceCharge() {
                window.wagesAltScEnabled = false;
                const chk = document.getElementById("chkUseAltServiceCharge");
                if (chk) chk.checked = false;
                const altBanner = document.getElementById("wagesAltAppliedBanner");
                if (altBanner) altBanner.style.display = "none";
                updateWagesPreview();

                // Save revert state to server
                saveWagesAltServiceChargeToServer(false, function(success) {
                    if (success) {
                        showToast("Reverted to standard service charge calculation and saved.", "info");
                    }
                });
            }

            function onToggleAltServiceCharge(enabled) {
                if (enabled) {
                    if (!window.wagesAltScData || window.wagesAltScData.dailyRate <= 0) {
                        showToast("Please enter an alternate daily rate first.", "warning");
                        document.getElementById("chkUseAltServiceCharge").checked = false;
                        return;
                    }
                    applyAltServiceChargeToMain();
                } else {
                    revertToStandardServiceCharge();
                }
            }

            function toggleAltGroupTable() {
                const container = document.getElementById("altGroupTableContainer");
                const icon = document.getElementById("altGroupToggleIcon");
                if (container) {
                    if (container.style.display === "none") {
                        container.style.display = "block";
                        if (icon) icon.innerHTML = '<i class="fas fa-chevron-up"></i>';
                    } else {
                        container.style.display = "none";
                        if (icon) icon.innerHTML = '<i class="fas fa-chevron-down"></i>';
                    }
                }
            }

            function exportWagesToExcel() {
                if (typeof XLSX === "undefined") {
                    showToast("Spreadsheet library is not loaded.", "error");
                    return;
                }

                const table = document.getElementById("wagesTable");
                if (!table || wagesEmployeesData.length === 0) {
                    showToast("No data available to export.", "warning");
                    return;
                }

                const wb = XLSX.utils.book_new();
                const data = [];

                // Extract header text values
                const contractText = document.getElementById("wagesHeaderContract").innerText;
                const categoryText = document.getElementById("wagesHeaderCategory").innerText;
                const periodText = document.getElementById("wagesHeaderPeriod").innerText;
                const vendorText = document.getElementById("wagesHeaderVendor").innerText;
                const paymentText = document.getElementById("wagesHeaderPayment").innerText;

                data.push([contractText]);
                data.push([categoryText]);
                data.push([periodText]);
                data.push([vendorText]);
                data.push([paymentText]);
                data.push([]); // blank row

                // Table headers
                const colCHeaderText = document.getElementById("wagesColCHeader").innerText;
                data.push(["Sl No.", "Description", colCHeaderText, "No of people", "No of Days/Individual", "Total No. of working days"]);

                // Table rows
                const rows = document.querySelectorAll("#wagesTableBody tr");
                rows.forEach(tr => {
                    const cells = tr.querySelectorAll("td");
                    data.push([
                        parseInt(cells[0].innerText),
                        parseFloat(cells[1].innerText),
                        parseFloat(cells[2].innerText),
                        parseInt(cells[3].innerText),
                        parseInt(cells[4].innerText),
                        parseInt(cells[5].innerText)
                    ]);
                });

                // Table footer matching Excel cells exactly
                const totalPeople = parseInt(document.getElementById("wagesTotalPeople").textContent);
                const totalDays = parseInt(document.getElementById("wagesTotalDays").textContent);
                data.push(["", "", "Total No of People", totalPeople, "Total No of Days", totalDays]);

                // Summary items inside the main table
                const wagesFormula = document.getElementById("wagesFormulaDesc").innerText;
                const wagesVal = parseFloat(document.getElementById("wagesAmountWages").innerText.replace(/,/g, ''));
                data.push(["", "", wagesFormula, "", "", wagesVal]);

                const epfCappedFormula = document.getElementById("wagesFormulaEpfCapped").innerText;
                const epfCappedVal = parseFloat(document.getElementById("wagesAmountEpfCapped").innerText.replace(/,/g, ''));
                data.push(["", "", "", epfCappedFormula, "", epfCappedVal]);

                const epfActualFormula = document.getElementById("wagesFormulaEpfActual").innerText;
                const epfActualVal = parseFloat(document.getElementById("wagesAmountEpfActual").innerText.replace(/,/g, ''));
                data.push(["", "", "", epfActualFormula, "", epfActualVal]);

                const subTotalVal = parseFloat(document.getElementById("wagesAmountSubTotal").innerText.replace(/,/g, ''));
                data.push(["", "", "", "Sub Total", "", subTotalVal]);

                const serviceChargeFormula = document.getElementById("wagesFormulaServiceCharge").innerText;
                const serviceChargeVal = parseFloat(document.getElementById("wagesAmountServiceCharge").innerText.replace(/,/g, ''));
                data.push(["", "", "", serviceChargeFormula, "", serviceChargeVal]);

                const gstFormula = document.getElementById("wagesFormulaGst").innerText;
                const gstVal = parseFloat(document.getElementById("wagesAmountGst").innerText.replace(/,/g, ''));
                data.push(["", "", "", "", gstFormula, gstVal]);

                const grandTotalVal = parseFloat(document.getElementById("wagesAmountGrandTotal").innerText.replace(/,/g, ''));
                data.push(["", "", "", "Total Cost Per Month", "", grandTotalVal]);

                const ws = XLSX.utils.aoa_to_sheet(data);

                // Merges
                ws["!merges"] = [
                    { s: { r: 0, c: 0 }, e: { r: 0, c: 5 } },
                    { s: { r: 1, c: 0 }, e: { r: 1, c: 5 } },
                    { s: { r: 2, c: 0 }, e: { r: 2, c: 5 } },
                    { s: { r: 3, c: 0 }, e: { r: 3, c: 5 } },
                    { s: { r: 4, c: 0 }, e: { r: 4, c: 5 } }
                ];

                // Widths
                ws["!cols"] = [
                    { wch: 8 },
                    { wch: 45 },
                    { wch: 30 },
                    { wch: 15 },
                    { wch: 20 },
                    { wch: 25 }
                ];

                // Apply formatting styles to ws
                // Headers styling (Row 1 to 5) -> Calibri 11 Bold, Centered
                const headerRowStyle = {
                    font: { bold: true, name: "Calibri", sz: 11 },
                    alignment: { horizontal: "center", vertical: "center" }
                };
                for (let r = 0; r < 5; r++) {
                    const cellRef = "A" + (r + 1);
                    if (ws[cellRef]) ws[cellRef].s = headerRowStyle;
                }

                // Table headers (Row 7) -> Calibri 11 Bold, Centered, Thin border
                const colHeaderStyle = {
                    font: { bold: true, name: "Calibri", sz: 11 },
                    alignment: { horizontal: "center", vertical: "center", wrapText: true },
                    border: {
                        top: { style: "thin", color: { auto: 1 } },
                        bottom: { style: "thin", color: { auto: 1 } },
                        left: { style: "thin", color: { auto: 1 } },
                        right: { style: "thin", color: { auto: 1 } }
                    }
                };
                for (let c = 0; c < 6; c++) {
                    const cellRef = String.fromCharCode(65 + c) + "7";
                    if (ws[cellRef]) ws[cellRef].s = colHeaderStyle;
                }

                // Body data rows -> Calibri 11, Thin border, proper alignments
                const bodyRowsCount = rows.length;
                for (let i = 0; i < bodyRowsCount; i++) {
                    const rowNum = 8 + i;
                    for (let c = 0; c < 6; c++) {
                        const cellRef = String.fromCharCode(65 + c) + rowNum;
                        if (ws[cellRef]) {
                            let alignH = "center";
                            if (c === 1) alignH = "left";
                            if (c === 2 || c === 5) alignH = "right";

                            ws[cellRef].s = {
                                font: { name: "Calibri", sz: 11 },
                                alignment: { horizontal: alignH, vertical: "center" },
                                border: {
                                    top: { style: "thin", color: { auto: 1 } },
                                    bottom: { style: "thin", color: { auto: 1 } },
                                    left: { style: "thin", color: { auto: 1 } },
                                    right: { style: "thin", color: { auto: 1 } }
                                }
                            };
                        }
                    }
                }

                // Summary footer rows -> Calibri 11 Bold, Thin border, aligned right
                const summaryStartRow = 8 + bodyRowsCount;
                for (let r = 0; r < 8; r++) {
                    const rowNum = summaryStartRow + r;
                    for (let c = 0; c < 6; c++) {
                        const cellRef = String.fromCharCode(65 + c) + rowNum;
                        if (ws[cellRef] && ws[cellRef].v !== "") {
                            let alignH = "right";
                            if (c === 2 || c === 3) alignH = "left";
                            if (c === 4) alignH = "right";

                            const isGrandTotal = (r === 7);

                            ws[cellRef].s = {
                                font: { bold: true, name: "Calibri", sz: 11 },
                                alignment: { horizontal: alignH, vertical: "center" },
                                border: {
                                    top: { style: "thin", color: { auto: 1 } },
                                    bottom: { style: isGrandTotal ? "double" : "thin", color: { auto: 1 } },
                                    left: { style: "thin", color: { auto: 1 } },
                                    right: { style: "thin", color: { auto: 1 } }
                                }
                            };
                        }
                    }
                }

                const monthText = document.getElementById("wagesMonth").options[document.getElementById("wagesMonth").selectedIndex].text;
                XLSX.utils.book_append_sheet(wb, ws, `${monthText} Salarywges`);

                // -- Build Break UP sheet --
                const breakupData = [];
                const bData = window.wagesBreakupData || {
                    title: "VALUE AS PER GOVT VALUE",
                    category: "DEO (Skilled)",
                    basic: 981,
                    epf: 69.23,
                    epfDesc: "EPF @ 12% of Basic Wages",
                    edli: 2.88,
                    edliDesc: "EPF ELDI @ 0.5% of Basic Wages",
                    admin: 2.88,
                    adminDesc: "EPF Admin @ 0.5% of Basic Wages",
                    gross: 1055.99
                };
                breakupData.push([bData.title]);
                breakupData.push([bData.category]);
                breakupData.push(["Sl No.", "Description", "Govt Value"]);

                breakupData.push(["1", "Basic Wages per day", bData.basic]);
                breakupData.push(["2", bData.epfDesc, bData.epf]);
                breakupData.push(["3", bData.edliDesc, bData.edli]);
                breakupData.push(["4", bData.adminDesc, bData.admin]);
                breakupData.push(["5", "Gross Salary/Day", bData.gross]);

                const wsBu = XLSX.utils.aoa_to_sheet(breakupData);

                wsBu["!merges"] = [
                    { s: { r: 0, c: 0 }, e: { r: 0, c: 2 } },
                    { s: { r: 1, c: 0 }, e: { r: 1, c: 2 } }
                ];

                wsBu["!cols"] = [
                    { wch: 8 },
                    { wch: 45 },
                    { wch: 15 }
                ];

                // Apply formatting styles to wsBu
                if (wsBu["A1"]) {
                    wsBu["A1"].s = {
                        font: { bold: true, name: "Calibri", sz: 11 },
                        alignment: { horizontal: "center", vertical: "center" }
                    };
                }
                if (wsBu["A2"]) {
                    wsBu["A2"].s = {
                        font: { bold: true, name: "Calibri", sz: 11 },
                        alignment: { horizontal: "center", vertical: "center" }
                    };
                }

                for (let c = 0; c < 3; c++) {
                    const cellRef = String.fromCharCode(65 + c) + "3";
                    if (wsBu[cellRef]) {
                        wsBu[cellRef].s = {
                            font: { bold: true, name: "Calibri", sz: 11 },
                            alignment: { horizontal: "center", vertical: "center" },
                            border: {
                                top: { style: "thin", color: { auto: 1 } },
                                bottom: { style: "thin", color: { auto: 1 } },
                                left: { style: "thin", color: { auto: 1 } },
                                right: { style: "thin", color: { auto: 1 } }
                            }
                        };
                    }
                }

                for (let r = 4; r <= 8; r++) {
                    for (let c = 0; c < 3; c++) {
                        const cellRef = String.fromCharCode(65 + c) + r;
                        if (wsBu[cellRef]) {
                            let alignH = "center";
                            if (c === 1) alignH = "left";
                            if (c === 2) alignH = "right";

                            const isGross = (r === 8);

                            wsBu[cellRef].s = {
                                font: { name: "Calibri", sz: 11, bold: isGross },
                                alignment: { horizontal: alignH, vertical: "center" },
                                border: {
                                    top: { style: "thin", color: { auto: 1 } },
                                    bottom: { style: isGross ? "double" : "thin", color: { auto: 1 } },
                                    left: { style: "thin", color: { auto: 1 } },
                                    right: { style: "thin", color: { auto: 1 } }
                                }
                            };
                        }
                    }
                }

                XLSX.utils.book_append_sheet(wb, wsBu, `${monthText} salary breakup`);

                const categoryVal = document.getElementById("wagesCategory").value;
                const yearVal = document.getElementById("wagesYear").value;
                const filename = `Wages_Calculation_${categoryVal}_${monthText}_${yearVal}.xlsx`;

                XLSX.writeFile(wb, filename);
                showToast("Wages Calculation sheet exported successfully!", "success");
            }

            function updateHeaderPreview() {
                const catInfo = getSelectedCategoryInfo(document.getElementById("category"));
                const catText = catInfo.cleanName;
                const vendorNameVal = document.getElementById("vendorName").value || "[Vendor Name]";
                const vendorAddrVal = document.getElementById("vendorAddress").value || "[Vendor Address]";
                const gemNoVal = document.getElementById("gemContractNo").value || "[GeM Contract No]";
                const gemDateVal = document.getElementById("gemContractDate").value || "[Contract Date]";
                const certDatedOnVal = document.getElementById("certDatedOnInput")?.value || "[Dated On]";

                const ySelect = document.getElementById("year");
                if (!ySelect || !ySelect.value) return;
                const yText = ySelect.value;

                const mSelect = document.getElementById("month");
                if (!mSelect || mSelect.selectedIndex === -1) return;
                const mText = mSelect.options[mSelect.selectedIndex].text;

                const daysInMonth = new Date(parseInt(yText), parseInt(mSelect.value) + 1, 0).getDate();

                // Set Title dynamically
                document.getElementById("certTitle").textContent = "CERTIFICATE";

                let catLabel = catInfo.val !== "All" ? catText : "Contract Staff";
                const startDateStr = `01-${mText}-${yText}`;
                const endDateStr = `${daysInMonth}-${mText}-${yText}`;

                // Read the template values from the textareas
                const tpl1El = document.getElementById("txtTplDesc1");
                const tpl2El = document.getElementById("txtTplDesc2");

                let currentTpl1 = tpl1El && tpl1El.value ? tpl1El.value : tplDesc1;
                let currentTpl2 = tpl2El && tpl2El.value ? tpl2El.value : tplDesc2;

                // Perform global replacements
                let desc1 = replacePlaceholders(currentTpl1, "attendance");
                let desc2 = replacePlaceholders(currentTpl2, "attendance");

                document.getElementById("certDesc1").innerHTML = desc1;
                document.getElementById("certDesc2").innerHTML = desc2;
            }

            function loadTemplates() {
                fetch('Documents.aspx/GetTemplates', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' }
                })
                    .then(r => r.json())
                    .then(res => {
                        const dict = JSON.parse(res.d || "{}");
                        if (dict.AttDesc1) {
                            tplDesc1 = dict.AttDesc1;
                        }
                        if (dict.AttDesc2) {
                            tplDesc2 = dict.AttDesc2;
                        }
                        if (dict.SatDesc1) {
                            tplSatDesc1 = dict.SatDesc1;
                        }
                        if (dict.SatDesc2) {
                            tplSatDesc2 = dict.SatDesc2;
                        }
                        if (dict.SatDesc3) {
                            tplSatDesc3 = dict.SatDesc3;
                        }
                        const tpl1El = document.getElementById("txtTplDesc1");
                        const tpl2El = document.getElementById("txtTplDesc2");
                        if (tpl1El) tpl1El.value = tplDesc1;
                        if (tpl2El) tpl2El.value = tplDesc2;

                        const satTpl1El = document.getElementById("txtSatTplDesc1");
                        const satTpl2El = document.getElementById("txtSatTplDesc2");
                        const satTpl3El = document.getElementById("txtSatTplDesc3");
                        if (satTpl1El) satTpl1El.value = tplSatDesc1;
                        if (satTpl2El) satTpl2El.value = tplSatDesc2;
                        if (satTpl3El) satTpl3El.value = tplSatDesc3;

                        // Load saved signatory, designation, services, pcno
                        const sigEl = document.getElementById("satSignatoryInput");
                        const desEl = document.getElementById("satDesignationInput");
                        const svcEl = document.getElementById("satServicesInput");
                        const pcnoEl = document.getElementById("satSignatoryPcnoInput");
                        if (dict.SatSignatory && sigEl) sigEl.value = dict.SatSignatory;
                        if (dict.SatDesignation && desEl) desEl.value = dict.SatDesignation;
                        if (dict.SatServices && svcEl) svcEl.value = dict.SatServices;
                        if (dict.SatSignatoryPcno && pcnoEl) pcnoEl.value = dict.SatSignatoryPcno;

                        // Load and apply layout settings
                        const satFontSizeEl = document.getElementById('satFontSizeInput');
                        const satSectionSpacingEl = document.getElementById('satSectionSpacingInput');
                        const satSigSpacingEl = document.getElementById('satSigSpacingInput');
                        const savedFontSize = parseInt(dict.SatFontSize) || 14;
                        const savedSectionSpacing = parseInt(dict.SatSectionSpacing) || 25;
                        const savedSigSpacing = parseInt(dict.SatSigSpacing) || 50;
                        if (satFontSizeEl) satFontSizeEl.value = savedFontSize;
                        if (satSectionSpacingEl) satSectionSpacingEl.value = savedSectionSpacing;
                        if (satSigSpacingEl) satSigSpacingEl.value = savedSigSpacing;
                        applySatLayout(savedFontSize, savedSectionSpacing, savedSigSpacing);

                        if (dict.CovPhone) tplCovPhone = dict.CovPhone;
                        if (dict.CovRefNo) tplCovRefNo = dict.CovRefNo;
                        if (dict.CovSubject) tplCovSubject = dict.CovSubject;
                        if (dict.CovBody) tplCovBody = dict.CovBody;
                        if (dict.CovSignatory) tplCovSignatory = dict.CovSignatory;
                        if (dict.CovDesignation) tplCovDesignation = dict.CovDesignation;
                        if (dict.CovAuthority) tplCovAuthority = dict.CovAuthority;
                        if (dict.CovRecipient) tplCovRecipient = dict.CovRecipient;

                        if (dict.WagesHdrContract) tplWagesHdrContract = dict.WagesHdrContract;
                        if (dict.WagesHdrCategory) tplWagesHdrCategory = dict.WagesHdrCategory;
                        if (dict.WagesHdrPeriod) tplWagesHdrPeriod = dict.WagesHdrPeriod;
                        if (dict.WagesHdrVendor) tplWagesHdrVendor = dict.WagesHdrVendor;
                        if (dict.WagesHdrPayment) tplWagesHdrPayment = dict.WagesHdrPayment;

                        // Dynamically populate all category descriptions from CertificateTemplates
                        Object.keys(dict).forEach(key => {
                            if (key.startsWith("WagesDesc_")) {
                                const rawKey = key.substring("WagesDesc_".length);
                                wagesCategoryDescriptions[rawKey] = dict[key];
                                const readable = rawKey.replace(/_/g, " ");
                                wagesCategoryDescriptions[readable] = dict[key];
                            }
                            if (key.startsWith("PocRepManpower_")) {
                                const rawKey = key.substring("PocRepManpower_".length);
                                pocRepCategoryDescriptions[rawKey] = dict[key];
                                const readable = rawKey.replace(/_/g, " ");
                                pocRepCategoryDescriptions[readable] = dict[key];
                            }
                        });

                        const covPhoneEl = document.getElementById("covPhoneInput");
                        const covRefNoEl = document.getElementById("covRefNoInput");
                        const covSubjectEl = document.getElementById("covSubjectInput");
                        const covBodyEl = document.getElementById("covBodyInput");
                        const covSignatoryEl = document.getElementById("covSignatoryInput");
                        const covDesignationEl = document.getElementById("covDesignationInput");
                        const covAuthorityEl = document.getElementById("covAuthorityInput");
                        const covRecipientEl = document.getElementById("covRecipientInput");
                        const covPcnoEl = document.getElementById("covSignatoryPcnoInput");

                        if (covPhoneEl) covPhoneEl.value = tplCovPhone;
                        if (covRefNoEl) covRefNoEl.value = tplCovRefNo;
                        if (covSubjectEl) covSubjectEl.value = tplCovSubject;
                        if (covBodyEl) covBodyEl.value = tplCovBody;
                        if (covSignatoryEl) covSignatoryEl.value = tplCovSignatory;
                        if (covDesignationEl) covDesignationEl.value = tplCovDesignation;
                        if (covAuthorityEl) covAuthorityEl.value = tplCovAuthority;
                        if (covRecipientEl) covRecipientEl.value = tplCovRecipient;
                        if (dict.CovSignatoryPcno && covPcnoEl) covPcnoEl.value = dict.CovSignatoryPcno;

                        // Load and apply covering letter layout settings
                        const covFontSizeEl = document.getElementById('covFontSizeInput');
                        const covSectionSpacingEl = document.getElementById('covSectionSpacingInput');
                        const covSigSpacingEl = document.getElementById('covSigSpacingInput');
                        const savedCovFontSize = parseInt(dict.CovFontSize) || 12;
                        const savedCovSectionSpacing = parseInt(dict.CovSectionSpacing) || 24;
                        const savedCovSigSpacing = parseInt(dict.CovSigSpacing) || 50;
                        if (covFontSizeEl) covFontSizeEl.value = savedCovFontSize;
                        if (covSectionSpacingEl) covSectionSpacingEl.value = savedCovSectionSpacing;
                        if (covSigSpacingEl) covSigSpacingEl.value = savedCovSigSpacing;
                        applyCovLayout(savedCovFontSize, savedCovSectionSpacing, savedCovSigSpacing);


                        const w1 = document.getElementById("txtWagesTplContract");
                        const w2 = document.getElementById("txtWagesTplCategory");
                        const w3 = document.getElementById("txtWagesTplPeriod");
                        const w4 = document.getElementById("txtWagesTplVendor");
                        const w5 = document.getElementById("txtWagesTplPayment");

                        if (w1) w1.value = tplWagesHdrContract;
                        if (w2) w2.value = tplWagesHdrCategory;
                        if (w3) w3.value = tplWagesHdrPeriod;
                        if (w4) w4.value = tplWagesHdrVendor;
                        if (w5) w5.value = tplWagesHdrPayment;



                        if (dict.RepTpl1Heading1) tplRepTpl1H1 = dict.RepTpl1Heading1;
                        if (dict.RepTpl1Heading2) tplRepTpl1H2 = dict.RepTpl1Heading2;
                        if (dict.RepTpl2Heading1) tplRepTpl2H1 = dict.RepTpl2Heading1;
                        if (dict.RepTpl2Heading2) tplRepTpl2H2 = dict.RepTpl2Heading2;

                        const rep1 = document.getElementById("txtRepTpl1Heading1");
                        const rep2 = document.getElementById("txtRepTpl1Heading2");
                        const rep3 = document.getElementById("txtRepTpl2Heading1");
                        const rep4 = document.getElementById("txtRepTpl2Heading2");
                        if (rep1) rep1.value = tplRepTpl1H1;
                        if (rep2) rep2.value = tplRepTpl1H2;
                        if (rep3) rep3.value = tplRepTpl2H1;
                        if (rep4) rep4.value = tplRepTpl2H2;

                        if (dict.PocRepTopLine1 && document.getElementById("txtPocRepTopLine1")) document.getElementById("txtPocRepTopLine1").value = dict.PocRepTopLine1;
                        if (dict.PocRepTopLine2 && document.getElementById("txtPocRepTopLine2")) document.getElementById("txtPocRepTopLine2").value = dict.PocRepTopLine2;
                        if (dict.PocRepTopFontSize && document.getElementById("pocRepTopFontSizeInput")) document.getElementById("pocRepTopFontSizeInput").value = dict.PocRepTopFontSize;
                        if (dict.PocRepTopAlign && document.getElementById("pocRepTopAlignInput")) document.getElementById("pocRepTopAlignInput").value = dict.PocRepTopAlign;
                        if (dict.PocRepCertParagraph && document.getElementById("txtPocRepCertParagraph")) document.getElementById("txtPocRepCertParagraph").value = dict.PocRepCertParagraph;
                        if (dict.PocRepSignatures && document.getElementById("txtPocRepSignatures")) document.getElementById("txtPocRepSignatures").value = dict.PocRepSignatures;
                        if (dict.PocRepBottomFontSize && document.getElementById("pocRepBottomFontSizeInput")) document.getElementById("pocRepBottomFontSizeInput").value = dict.PocRepBottomFontSize;
                        if (dict.PocRepBottomAlign && document.getElementById("pocRepBottomAlignInput")) document.getElementById("pocRepBottomAlignInput").value = dict.PocRepBottomAlign;

                        updateHeaderPreview();
                        updateSatPreview();
                        updateCovPreview();
                        if (typeof onWagesTplCategoryChange === 'function') {
                            onWagesTplCategoryChange();
                        }
                        if (typeof onPocRepCategoryChange === 'function') {
                            onPocRepCategoryChange();
                        }
                    })
                    .catch(() => {
                        const tpl1El = document.getElementById("txtTplDesc1");
                        const tpl2El = document.getElementById("txtTplDesc2");
                        if (tpl1El) tpl1El.value = tplDesc1;
                        if (tpl2El) tpl2El.value = tplDesc2;

                        const satTpl1El = document.getElementById("txtSatTplDesc1");
                        const satTpl2El = document.getElementById("txtSatTplDesc2");
                        const satTpl3El = document.getElementById("txtSatTplDesc3");
                        if (satTpl1El) satTpl1El.value = tplSatDesc1;
                        if (satTpl2El) satTpl2El.value = tplSatDesc2;
                        if (satTpl3El) satTpl3El.value = tplSatDesc3;

                        const covPhoneEl = document.getElementById("covPhoneInput");
                        const covRefNoEl = document.getElementById("covRefNoInput");
                        const covSubjectEl = document.getElementById("covSubjectInput");
                        const covBodyEl = document.getElementById("covBodyInput");
                        const covSignatoryEl = document.getElementById("covSignatoryInput");
                        const covDesignationEl = document.getElementById("covDesignationInput");
                        const covAuthorityEl = document.getElementById("covAuthorityInput");
                        const covRecipientEl = document.getElementById("covRecipientInput");

                        if (covPhoneEl) covPhoneEl.value = tplCovPhone;
                        if (covRefNoEl) covRefNoEl.value = tplCovRefNo;
                        if (covSubjectEl) covSubjectEl.value = tplCovSubject;
                        if (covBodyEl) covBodyEl.value = tplCovBody;
                        if (covSignatoryEl) covSignatoryEl.value = tplCovSignatory;
                        if (covDesignationEl) covDesignationEl.value = tplCovDesignation;
                        if (covAuthorityEl) covAuthorityEl.value = tplCovAuthority;
                        if (covRecipientEl) covRecipientEl.value = tplCovRecipient;

                        const w1 = document.getElementById("txtWagesTplContract");
                        const w2 = document.getElementById("txtWagesTplCategory");
                        const w3 = document.getElementById("txtWagesTplPeriod");
                        const w4 = document.getElementById("txtWagesTplVendor");
                        const w5 = document.getElementById("txtWagesTplPayment");

                        if (w1) w1.value = tplWagesHdrContract;
                        if (w2) w2.value = tplWagesHdrCategory;
                        if (w3) w3.value = tplWagesHdrPeriod;
                        if (w4) w4.value = tplWagesHdrVendor;
                        if (w5) w5.value = tplWagesHdrPayment;

                        const rep1 = document.getElementById("txtRepTpl1Heading1");
                        const rep2 = document.getElementById("txtRepTpl1Heading2");
                        const rep3 = document.getElementById("txtRepTpl2Heading1");
                        const rep4 = document.getElementById("txtRepTpl2Heading2");
                        if (rep1) rep1.value = tplRepTpl1H1;
                        if (rep2) rep2.value = tplRepTpl1H2;
                        if (rep3) rep3.value = tplRepTpl2H1;
                        if (rep4) rep4.value = tplRepTpl2H2;

                        updateHeaderPreview();
                        updateSatPreview();
                        updateCovPreview();
                        showToast("Failed to load templates from database. Using defaults.", "warning");
                    });
            }

            function saveTpl() {
                const desc1 = document.getElementById("txtTplDesc1").value;
                const desc2 = document.getElementById("txtTplDesc2").value;

                if (!desc1.trim() || !desc2.trim()) {
                    showToast("Templates cannot be empty.", "warning");
                    return;
                }

                fetch('Documents.aspx/SaveTemplates', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ desc1: desc1, desc2: desc2 })
                })
                    .then(r => r.json())
                    .then(res => {
                        const data = JSON.parse(res.d || "{}");
                        if (data.status === "success") {
                            tplDesc1 = desc1;
                            tplDesc2 = desc2;
                            showToast("Templates saved successfully to database.", "success");
                            updateHeaderPreview();
                        } else {
                            showToast(data.message || "Failed to save templates.", "error");
                        }
                    })
                    .catch(() => showToast("Error saving templates.", "error"));
            }

            function saveSatTpl() {
                const desc1 = document.getElementById("txtSatTplDesc1").value;
                const desc2 = document.getElementById("txtSatTplDesc2").value;
                const desc3 = document.getElementById("txtSatTplDesc3").value;
                const signatory = document.getElementById("satSignatoryInput").value;
                const designation = document.getElementById("satDesignationInput").value;
                const services = document.getElementById("satServicesInput").value;
                const pcno = document.getElementById("satSignatoryPcnoInput")?.value || "";
                const fontSizePt = parseInt(document.getElementById("satFontSizeInput")?.value) || 14;
                const sectionSpacingPt = parseInt(document.getElementById("satSectionSpacingInput")?.value) || 25;
                const sigSpacingPt = parseInt(document.getElementById("satSigSpacingInput")?.value) || 50;

                if (!desc1.trim() || !desc2.trim() || !desc3.trim()) {
                    showToast("Templates cannot be empty.", "warning");
                    return;
                }

                fetch('Documents.aspx/SaveSatTemplates', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ desc1: desc1, desc2: desc2, desc3: desc3, signatory: signatory, designation: designation, services: services, pcno: pcno, fontSizePt: fontSizePt, sectionSpacingPt: sectionSpacingPt, sigSpacingPt: sigSpacingPt })
                })
                    .then(r => r.json())
                    .then(res => {
                        const data = JSON.parse(res.d || "{}");
                        if (data.status === "success") {
                            tplSatDesc1 = desc1;
                            tplSatDesc2 = desc2;
                            tplSatDesc3 = desc3;
                            applySatLayout(fontSizePt, sectionSpacingPt, sigSpacingPt);
                            showToast("Satisfactory Certificate settings saved successfully.", "success");
                            updateSatPreview();
                        } else {
                            showToast(data.message || "Failed to save.", "error");
                        }
                    })
                    .catch(() => showToast("Error saving templates.", "error"));
            }

            function fetchSignatoryDetails() {
                const pcnoInput = document.getElementById("satSignatoryPcnoInput");
                const pcno = pcnoInput ? pcnoInput.value.trim() : "";
                if (!pcno) {
                    showToast("Please enter a PCNO first.", "warning");
                    return;
                }

                showToast("Fetching signatory details...", "info");

                fetch('Documents.aspx/GetEmployeeDetailsByPCNO', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ pcno: pcno })
                })
                .then(r => r.json())
                .then(res => {
                    const data = JSON.parse(res.d || "{}");
                    if (data.status === "success") {
                        const sigInput = document.getElementById("satSignatoryInput");
                        const desInput = document.getElementById("satDesignationInput");
                        
                        if (sigInput) sigInput.value = data.name || "";
                        if (desInput) desInput.value = data.designation || "";
                        
                        showToast("Signatory details fetched successfully!", "success");
                        updateSatPreview();
                    } else {
                        showToast(data.message || "Failed to fetch details.", "error");
                    }
                })
                .catch(err => {
                    console.error(err);
                    showToast("Error communicating with backend.", "error");
                });
            }

            function saveWagesTpl() {
                const hContract = document.getElementById("txtWagesTplContract").value;
                const hCategory = document.getElementById("txtWagesTplCategory").value;
                const hPeriod = document.getElementById("txtWagesTplPeriod").value;
                const hVendor = document.getElementById("txtWagesTplVendor").value;
                const hPayment = document.getElementById("txtWagesTplPayment").value;
                const catVal = document.getElementById("wagesTplCategorySelect").value;
                const catDescVal = document.getElementById("wagesTplCategoryDescInput").value;


                if (!hContract.trim() || !hCategory.trim() || !hPeriod.trim() || !hVendor.trim() || !hPayment.trim()) {
                    showToast("Templates cannot be empty.", "warning");
                    return;
                }
                if (!catVal || catVal === "All" || !catDescVal.trim()) {
                    showToast("Category and Category Description cannot be empty.", "warning");
                    return;
                }


                fetch('Documents.aspx/SaveWagesTemplates', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        hdrContract: hContract,
                        hdrCategory: hCategory,
                        hdrPeriod: hPeriod,
                        hdrVendor: hVendor,
                        hdrPayment: hPayment,
                        category: catVal,
                        categoryDesc: catDescVal
                    })
                })
                    .then(r => r.json())
                    .then(res => {
                        const data = JSON.parse(res.d || "{}");
                        if (data.status === "success") {
                            tplWagesHdrContract = hContract;
                            tplWagesHdrCategory = hCategory;
                            tplWagesHdrPeriod = hPeriod;
                            tplWagesHdrVendor = hVendor;
                            tplWagesHdrPayment = hPayment;
                            wagesCategoryDescriptions[catVal] = catDescVal;



                            updateWagesPreview();
                            showToast(data.message || "Templates saved successfully.", "success");
                        } else {
                            showToast(data.message || "Failed to save templates.", "error");
                        }
                    })
                    .catch(() => showToast("Error saving templates.", "error"));
            }

            function saveReportTpl() {
                const t1h1 = document.getElementById("txtRepTpl1Heading1").value;
                const t1h2 = document.getElementById("txtRepTpl1Heading2").value;
                const t2h1 = document.getElementById("txtRepTpl2Heading1").value;
                const t2h2 = document.getElementById("txtRepTpl2Heading2").value;

                if (!t1h1.trim() || !t1h2.trim() || !t2h1.trim() || !t2h2.trim()) {
                    showToast("Templates cannot be empty.", "warning");
                    return;
                }

                fetch('Documents.aspx/SaveReportTemplates', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        tpl1H1: t1h1,
                        tpl1H2: t1h2,
                        tpl2H1: t2h1,
                        tpl2H2: t2h2
                    })
                })
                    .then(r => r.json())
                    .then(res => {
                        const data = JSON.parse(res.d || "{}");
                        if (data.status === "success") {
                            tplRepTpl1H1 = t1h1;
                            tplRepTpl1H2 = t1h2;
                            tplRepTpl2H1 = t2h1;
                            tplRepTpl2H2 = t2h2;

                            onRepTemplateSelectChange();
                            showToast(data.message || "Templates saved successfully.", "success");
                        } else {
                            showToast(data.message || "Failed to save templates.", "error");
                        }
                    })
                    .catch(() => showToast("Error saving templates.", "error"));
            }

            function savePocReportTpl() {
                const topLine1 = document.getElementById("txtPocRepTopLine1") ? document.getElementById("txtPocRepTopLine1").value : "";
                const topLine2 = document.getElementById("txtPocRepTopLine2") ? document.getElementById("txtPocRepTopLine2").value : "";
                const topFontSize = document.getElementById("pocRepTopFontSizeInput") ? document.getElementById("pocRepTopFontSizeInput").value : "11";
                const topAlign = document.getElementById("pocRepTopAlignInput") ? document.getElementById("pocRepTopAlignInput").value : "center";
                const certPara = document.getElementById("txtPocRepCertParagraph") ? document.getElementById("txtPocRepCertParagraph").value : "";
                const signatures = document.getElementById("txtPocRepSignatures") ? document.getElementById("txtPocRepSignatures").value : "";
                const bottomFontSize = document.getElementById("pocRepBottomFontSizeInput") ? document.getElementById("pocRepBottomFontSizeInput").value : "11";
                const bottomAlign = document.getElementById("pocRepBottomAlignInput") ? document.getElementById("pocRepBottomAlignInput").value : "left";
                const curCat = document.getElementById("pocRepCategorySelect") ? document.getElementById("pocRepCategorySelect").value : "";
                const curDesc = document.getElementById("pocRepCategoryDescInput") ? document.getElementById("pocRepCategoryDescInput").value : "";

                if (!topLine1.trim() || !topLine2.trim() || !certPara.trim()) {
                    showToast("Header lines and certification statement cannot be empty.", "warning");
                    return;
                }

                if (curCat && curDesc) {
                    pocRepCategoryDescriptions[curCat] = curDesc;
                    const safeCat = curCat.replace(/-/g, '_').replace(/ /g, '_');
                    pocRepCategoryDescriptions[safeCat] = curDesc;
                }

                fetch('Documents.aspx/SavePocReportTemplates', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        topLine1: topLine1,
                        topLine2: topLine2,
                        topFontSize: topFontSize,
                        topAlign: topAlign,
                        certPara: certPara,
                        signatures: signatures,
                        bottomFontSize: bottomFontSize,
                        bottomAlign: bottomAlign,
                        category: curCat,
                        categoryDesc: curDesc,
                        manpowerDefault: "DEO",
                        allCategoryDescriptionsJson: JSON.stringify(pocRepCategoryDescriptions)
                    })
                })
                    .then(r => r.json())
                    .then(res => {
                        const data = JSON.parse(res.d || "{}");
                        if (data.status === "success") {
                            showToast(data.message || "POC Monthly Report templates saved successfully.", "success");
                        } else {
                            showToast(data.message || "Failed to save templates.", "error");
                        }
                    })
                    .catch(() => showToast("Error saving POC report templates.", "error"));
            }

            // Fetch Live Attendance Data
            function loadData() {
                const yearElem = document.getElementById("year");
                const monthElem = document.getElementById("month");
                const catElem = document.getElementById("category");
                if (!yearElem || !monthElem || !catElem || !yearElem.value || !monthElem.value || !catElem.value) return;
                const yearVal = parseInt(yearElem.value);
                const monthVal = parseInt(monthElem.value);
                const catVal = catElem.value;
                if (isNaN(yearVal) || isNaN(monthVal)) return;

                const loader = document.getElementById("previewLoader");
                const previewArea = document.getElementById("previewArea");

                loader.style.display = "block";
                previewArea.style.display = "none";
                const contractSel = document.getElementById("contract");
                const selectedCpId = contractSel && contractSel.value ? parseInt(contractSel.value) : null;

                fetch('Documents.aspx/GetCertificateData', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ year: yearVal, month: monthVal, category: catVal, contractPeriodId: selectedCpId })
                })
                    .then(r => r.json())
                    .then(res => {
                        employeesData = JSON.parse(res.d || "[]");
                        if (employeesData.error) {
                            showToast(employeesData.error, "error");
                            loader.style.display = "none";
                            return;
                        }
                        renderPreviewTable();
                        loader.style.display = "none";
                        previewArea.style.display = "block";
                        showToast(`Loaded ${employeesData.length} records successfully!`, "success");
                    })
                    .catch(() => {
                        loader.style.display = "none";
                        showToast("Failed to retrieve certificate data.", "error");
                    });
            }

            // Render table dynamically
            function renderPreviewTable() {
                const tableBody = document.querySelector("#certTable tbody");
                if (!tableBody) return;

                let bodyHtml = "";
                let sNoIdx = 1;

                if (employeesData.length === 0) {
                    tableBody.innerHTML = `<tr><td colspan="10" class="text-center font-weight-bold py-4">No employees matching search criteria in this month.</td></tr>`;
                    return;
                }

                employeesData.forEach(emp => {
                    bodyHtml += "<tr>";
                    bodyHtml += `<td class="col-sno">${sNoIdx++}</td>`;
                    bodyHtml += `<td class="col-id">${emp.EmployeeId}</td>`;
                    bodyHtml += `<td class="col-masterid" style="display: none;">${emp.MasterId}</td>`;
                    bodyHtml += `<td class="col-name text-left" style="text-align: left; padding-left: 20px; font-weight: bold;">${emp.Name}</td>`;
                    bodyHtml += `<td class="col-present" style="display: none;">${emp.PresentDays}</td>`;
                    bodyHtml += `<td class="col-final" style="${emp.IsOverridden ? 'color: #ea580c; font-weight: bold;' : ''}">${emp.FinalDays}</td>`;
                    bodyHtml += `<td class="col-paid">${emp.Paid}</td>`;
                    bodyHtml += `<td class="col-unpaid">${emp.Unpaid}</td>`;
                    bodyHtml += `<td class="col-satcut">${emp.SatCut}</td>`;

                    // Remarks builders
                    const remarkCellVal = getRemarksString(emp);
                    bodyHtml += `<td class="col-remarks text-left" style="text-align: left;">${remarkCellVal}</td>`;
                    bodyHtml += "</tr>";
                });

                tableBody.innerHTML = bodyHtml;

                // Set initial visibility states based on configuration checkmarks
                applyAllColumnToggles();
            }

            // Auto-remarks string builder
            function getRemarksString(emp) {
                const parts = [];
                const includeJoinResign = document.getElementById("remJoinResign").checked;
                const includeOverride = document.getElementById("remOverride").checked;
                const includePair = document.getElementById("remPairs").checked;
                const includeSatEdit = document.getElementById("remSatEdit").checked;
                const includeCellSpecific = document.getElementById("remCellSpecific").checked;

                if (includeJoinResign && emp.JoinResignRemark) parts.push(emp.JoinResignRemark);
                if (includeOverride && emp.OverrideRemark) parts.push(emp.OverrideRemark);
                if (includePair && emp.LeavePairRemark) parts.push(emp.LeavePairRemark);
                if (includeSatEdit && emp.SaturdayRemark) parts.push(emp.SaturdayRemark);
                if (includeCellSpecific && emp.CellRemarks) parts.push(emp.CellRemarks);

                return parts.join("; ");
            }

            // Rebuild Remarks Column values when builder checkboxes change (preserving SNo index and DOM elements)
            function rebuildRemarksColumn() {
                const rows = document.querySelectorAll("#certTable tbody tr");
                if (rows.length === 0 || employeesData.length === 0) return;

                rows.forEach((row, i) => {
                    const emp = employeesData[i];
                    if (!emp) return;
                    const remarksCell = row.querySelector(".col-remarks");
                    if (remarksCell) {
                        remarksCell.textContent = getRemarksString(emp);
                    }
                });
                showToast("Remarks column rebuilt.", "success");
            }

            // Dynamic column toggle (Client-side style update)
            function toggleColumn(colClass, isChecked) {
                const elements = document.querySelectorAll("#certTable ." + colClass);
                elements.forEach(el => {
                    el.style.display = isChecked ? "" : "none";
                });
            }

            function applyAllColumnToggles() {
                toggleColumn("col-sno", document.getElementById("colSNo").checked);
                toggleColumn("col-id", document.getElementById("colID").checked);
                toggleColumn("col-masterid", document.getElementById("colMasterID").checked);
                toggleColumn("col-name", document.getElementById("colName").checked);
                toggleColumn("col-present", document.getElementById("colPresent").checked);
                toggleColumn("col-final", document.getElementById("colFinal").checked);
                toggleColumn("col-paid", document.getElementById("colPaid").checked);
                toggleColumn("col-unpaid", document.getElementById("colUnpaid").checked);
                toggleColumn("col-satcut", document.getElementById("colSatCut").checked);
                toggleColumn("col-remarks", document.getElementById("colRemarks").checked);
            }

            // Client-side Excel export mirroring active DOM modifications
            function exportToExcel() {
                if (typeof XLSX === "undefined") {
                    showToast("Spreadsheet library is not loaded.", "error");
                    return;
                }

                const table = document.getElementById("certTable");
                if (!table || employeesData.length === 0) {
                    showToast("No data available to export.", "warning");
                    return;
                }

                // Helper to decode HTML entities (like &amp; to &)
                function decodeHTMLEntities(text) {
                    if (!text) return "";
                    const temp = document.createElement('div');
                    temp.innerHTML = text;
                    return temp.textContent || temp.innerText || "";
                }

                // Get current heading texts and decode entities
                const certTitle = decodeHTMLEntities(document.getElementById("certTitle").textContent.trim());
                const certDesc1 = decodeHTMLEntities(document.getElementById("certDesc1").textContent.trim());
                const certDesc2 = decodeHTMLEntities(document.getElementById("certDesc2").textContent.trim());

                const AOA = [
                    [certTitle],
                    [certDesc1],
                    [certDesc2]
                ];

                // 1. Write Header Column Names (filtering hidden columns)
                const headers = [];
                const headerCells = document.querySelectorAll("#certTable thead tr th");
                headerCells.forEach(th => {
                    if (th.style.display !== "none") {
                        headers.push(decodeHTMLEntities(th.innerText.trim()));
                    }
                });
                AOA.push(headers);

                // 2. Write Data Rows (filtering hidden cells and decoding custom edited texts)
                const rows = document.querySelectorAll("#certTable tbody tr");
                rows.forEach(tr => {
                    const rowVals = [];
                    const cells = tr.querySelectorAll("td");
                    cells.forEach(td => {
                        if (td.style.display !== "none") {
                            rowVals.push(decodeHTMLEntities(td.innerText.trim()));
                        }
                    });
                    AOA.push(rowVals);
                });

                // Write Worksheet
                const ws = XLSX.utils.aoa_to_sheet(AOA);
                const wb = XLSX.utils.book_new();

                // Set column widths based on visibility
                const colWidths = [];
                let headerIdx = 0;
                headerCells.forEach(th => {
                    if (th.style.display !== "none") {
                        const text = th.innerText.toLowerCase();
                        if (text.includes("name")) colWidths.push({ wch: 30 });
                        else if (text.includes("remark")) colWidths.push({ wch: 45 });
                        else if (text.includes("master")) colWidths.push({ wch: 15 });
                        else if (text.includes("days") || text.includes("total")) colWidths.push({ wch: 12 });
                        else colWidths.push({ wch: 8 });
                        headerIdx++;
                    }
                });
                ws["!cols"] = colWidths;

                // Merge titles dynamically across all visible columns
                const lastColIndex = headers.length - 1;
                ws["!merges"] = [
                    { s: { r: 0, c: 0 }, e: { r: 0, c: lastColIndex } },
                    { s: { r: 1, c: 0 }, e: { r: 1, c: lastColIndex } },
                    { s: { r: 2, c: 0 }, e: { r: 2, c: lastColIndex } }
                ];

                // Helper to get Excel column letters (A, B, C, ...)
                function getColLetter(index) {
                    return String.fromCharCode(65 + index);
                }

                // Apply formatting styles to cells in worksheet
                // A1: Title styling (Calibri 11 Bold, Centered)
                if (ws["A1"]) {
                    ws["A1"].s = {
                        font: { bold: true, name: "Calibri", sz: 11 },
                        alignment: { horizontal: "center", vertical: "center" }
                    };
                }

                // Keep certificate description rows normal (not bold) in Excel as requested
                const desc1Style = {
                    font: { name: "Calibri", sz: 10, bold: false },
                    alignment: { horizontal: "center", vertical: "center", wrapText: true }
                };
                const desc2Style = {
                    font: { name: "Calibri", sz: 10, bold: false },
                    alignment: { horizontal: "center", vertical: "center", wrapText: true }
                };

                if (ws["A2"]) {
                    ws["A2"].s = desc1Style;
                }
                if (ws["A3"]) {
                    ws["A3"].s = desc2Style;
                }

                // A4 onwards: Header columns styling (Row index 3 in AOA is Row 4 in Excel, Calibri 11 Bold, Centered)
                for (let c = 0; c <= lastColIndex; c++) {
                    const cellRef = getColLetter(c) + "4";
                    if (ws[cellRef]) {
                        ws[cellRef].s = {
                            font: { bold: true, name: "Calibri", sz: 11 },
                            alignment: { horizontal: "center", vertical: "center" },
                            border: {
                                top: { style: "thin", color: { auto: 1 } },
                                bottom: { style: "thin", color: { auto: 1 } },
                                left: { style: "thin", color: { auto: 1 } },
                                right: { style: "thin", color: { auto: 1 } }
                            }
                        };
                    }
                }

                // Data rows styling (Row index 4 onwards in AOA is Row 5 onwards in Excel, Calibri 11, centered/left borders)
                for (let r = 4; r < AOA.length; r++) {
                    const rowNum = r + 1;
                    for (let c = 0; c <= lastColIndex; c++) {
                        const cellRef = getColLetter(c) + rowNum;
                        if (ws[cellRef]) {
                            const headerText = headers[c].toLowerCase();
                            // Left-align Name & Remarks; Center-align everything else
                            const alignHoriz = (headerText.includes("name") || headerText.includes("remark")) ? "left" : "center";

                            // Employee name is bold on the screen, so keep it bold in Excel
                            const isNameCol = headerText.includes("name");

                            ws[cellRef].s = {
                                font: { name: "Calibri", sz: 11, bold: isNameCol },
                                alignment: { horizontal: alignHoriz, vertical: "center", wrapText: headerText.includes("remark") },
                                border: {
                                    top: { style: "thin", color: { auto: 1 } },
                                    bottom: { style: "thin", color: { auto: 1 } },
                                    left: { style: "thin", color: { auto: 1 } },
                                    right: { style: "thin", color: { auto: 1 } }
                                }
                            };
                        }
                    }
                }

                XLSX.utils.book_append_sheet(wb, ws, "Attendance Certificate");

                // Format Filename
                const catVal = document.getElementById("category").value;
                const monthSel = document.getElementById("month");
                const mText = monthSel.options[monthSel.selectedIndex].text;
                const yearVal = document.getElementById("year").value;

                XLSX.writeFile(wb, `Attendance_Certificate_${mText}_${yearVal}_${catVal}.xlsx`);
                showToast("Downloaded Excel file successfully!", "success");
            }

            // --- Attendance Report Script Logic ---
            let reportEmployeesData = [];
            let reportContractsList = [];

            function populateReportSelectors() {
                const yearSel = document.getElementById("repYear");
                const monthSel = document.getElementById("repMonth");
                const categorySel = document.getElementById("repCategory");

                // Fill Year if empty
                if (yearSel.innerHTML === "") {
                    const currYear = new Date().getFullYear();
                    for (let y = currYear - 2; y <= currYear + 2; y++) {
                        yearSel.innerHTML += `<option value="${y}">${y}</option>`;
                    }
                    yearSel.value = currYear;
                }

                // Fill Month if empty
                if (monthSel.innerHTML === "") {
                    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                    months.forEach((m, i) => {
                        monthSel.innerHTML += `<option value="${i}">${m}</option>`;
                    });
                    monthSel.value = new Date().getMonth();
                }

                // Fill Categories if empty
                if (categorySel.innerHTML === "" || categorySel.options.length === 0) {
                    fillCategoryDropdown(categorySel);
                }

                onReportFilterChange();
            }

            function onReportFilterChange() {
                const yearElem = document.getElementById("repYear");
                const monthElem = document.getElementById("repMonth");
                const catElem = document.getElementById("repCategory");
                if (!yearElem || !monthElem || !catElem || !yearElem.value || !monthElem.value || !catElem.value) return;
                const yearVal = parseInt(yearElem.value);
                const monthVal = parseInt(monthElem.value);
                const catVal = catElem.value;
                if (isNaN(yearVal) || isNaN(monthVal)) return;

                if (catVal === "All") {
                    document.getElementById("repContractGroup").style.display = "none";
                    document.getElementById("repDatedOnGroup").style.display = "none";
                    document.getElementById("repContract").innerHTML = "";
                    document.getElementById("repDatedOnInput").value = "";
                    onRepTemplateSelectChange();
                    loadReportData();
                    return;
                }

                fetch('Documents.aspx/GetContractsForMonth', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ year: yearVal, month: monthVal, category: catVal })
                })
                    .then(r => r.json())
                    .then(res => {
                        reportContractsList = JSON.parse(res.d || "[]");
                        const contractSel = document.getElementById("repContract");
                        const contractGroup = document.getElementById("repContractGroup");
                        const datedOnGroup = document.getElementById("repDatedOnGroup");

                        if (reportContractsList.length > 0) {
                            let optionsHtml = "";
                            reportContractsList.forEach(c => {
                                optionsHtml += `<option value="${c.Id}">${c.DisplayName}</option>`;
                            });
                            contractSel.innerHTML = optionsHtml;
                            contractGroup.style.display = "block";
                            datedOnGroup.style.display = "block";
                            onReportContractChange();
                        } else {
                            contractGroup.style.display = "none";
                            datedOnGroup.style.display = "none";
                            contractSel.innerHTML = "";
                            document.getElementById("repDatedOnInput").value = "";
                            onRepTemplateSelectChange();
                            loadReportData();
                        }
                    })
                    .catch(() => showToast("Failed to fetch contract periods.", "error"));
            }

            function onReportContractChange() {
                const contractSel = document.getElementById("repContract");
                const selectedId = parseInt(contractSel.value);
                const contract = reportContractsList.find(c => c.Id === selectedId);
                if (contract) {
                    document.getElementById("repDatedOnInput").value = contract.VendorDatedOn || "";
                }
                onRepTemplateSelectChange();
                loadReportData();
            }

            function onRepTemplateSelectChange() {
                const tpl = document.getElementById("repTemplateSelect").value;
                const yearVal = document.getElementById("repYear").value;
                const monthSel = document.getElementById("repMonth");
                const monthText = monthSel.options[monthSel.selectedIndex] ? monthSel.options[monthSel.selectedIndex].text : "";
                const catVal = document.getElementById("repCategory").value;

                const contractSel = document.getElementById("repContract");
                const selectedId = parseInt(contractSel.value);
                const contract = reportContractsList.find(c => c.Id === selectedId);

                const vendorName = contract ? (contract.VendorName || "") : "VISHAL MANPOWER & SECURITY CONSULTANTS";
                const vendorAddress = contract ? (contract.VendorAddress || "") : "Mangalore";
                const gemNo = contract ? (contract.GemId || "") : "GEMC-511687761569464";
                const contractPeriod = contract ? (contract.DisplayName || "") : "";
                const datedOn = document.getElementById("repDatedOnInput").value || "[Dated On]";

                let heading1 = "";
                let heading2 = "";

                if (tpl === "tpl1") {
                    heading1 = tplRepTpl1H1;
                    heading2 = tplRepTpl1H2;
                } else {
                    heading1 = tplRepTpl2H1;
                    heading2 = tplRepTpl2H2;
                }

                // Perform placeholder replacements using the global helper
                document.getElementById("repHeadingLine1").value = replacePlaceholders(heading1, "report");
                document.getElementById("repHeadingLine2").value = replacePlaceholders(heading2, "report");
                updateReportHeaderPreview();
            }

            function updateReportHeaderPreview() {
                document.getElementById("repTitle1").textContent = document.getElementById("repHeadingLine1").value;
                document.getElementById("repTitle2").textContent = document.getElementById("repHeadingLine2").value;
            }

            function loadReportData() {
                const yearElem = document.getElementById("repYear");
                const monthElem = document.getElementById("repMonth");
                const catElem = document.getElementById("repCategory");
                if (!yearElem || !monthElem || !catElem || !yearElem.value || !monthElem.value || !catElem.value) return;
                const yearVal = parseInt(yearElem.value);
                const monthVal = parseInt(monthElem.value);
                const catVal = catElem.value;
                if (isNaN(yearVal) || isNaN(monthVal)) return;

                const loader = document.getElementById("previewLoader");
                const previewArea = document.getElementById("reportPreviewArea");

                loader.style.display = "block";
                previewArea.style.display = "none";
                const contractSel = document.getElementById("repContract");
                const selectedCpId = contractSel && contractSel.value ? parseInt(contractSel.value) : null;

                fetch('Documents.aspx/GetCertificateData', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ year: yearVal, month: monthVal, category: catVal, contractPeriodId: selectedCpId })
                })
                    .then(r => r.json())
                    .then(res => {
                        reportEmployeesData = JSON.parse(res.d || "[]");
                        if (reportEmployeesData.error) {
                            showToast(reportEmployeesData.error, "error");
                            loader.style.display = "none";
                            return;
                        }
                        updateReportHeaderPreview();
                        renderReportTable();
                        loader.style.display = "none";
                        previewArea.style.display = "block";
                        showToast(`Loaded ${reportEmployeesData.length} records successfully!`, "success");
                    })
                    .catch(() => {
                        loader.style.display = "none";
                        showToast("Failed to retrieve report data.", "error");
                    });
            }

            function renderReportTable() {
                const tableBody = document.querySelector("#reportTable tbody");
                if (!tableBody) return;

                let bodyHtml = "";
                let sNoIdx = 1;

                if (reportEmployeesData.length === 0) {
                    tableBody.innerHTML = `<tr><td colspan="10" class="text-center font-weight-bold py-4">No employees matching search criteria in this month.</td></tr>`;
                    return;
                }

                reportEmployeesData.forEach(emp => {
                    bodyHtml += "<tr>";
                    bodyHtml += `<td class="rep-col-sno">${sNoIdx++}</td>`;
                    bodyHtml += `<td class="rep-col-id">${emp.EmployeeId}</td>`;
                    bodyHtml += `<td class="rep-col-masterid" style="display: none;">${emp.MasterId}</td>`;
                    bodyHtml += `<td class="rep-col-name text-left" style="text-align: left; padding-left: 20px; font-weight: bold;">${emp.Name}</td>`;
                    bodyHtml += `<td class="rep-col-present">${emp.PresentDays}</td>`;
                    bodyHtml += `<td class="rep-col-final" style="display: none; ${emp.IsOverridden ? 'color: #ea580c; font-weight: bold;' : ''}">${emp.FinalDays}</td>`;
                    bodyHtml += `<td class="rep-col-paid" style="display: none;">${emp.Paid}</td>`;
                    bodyHtml += `<td class="rep-col-unpaid" style="display: none;">${emp.Unpaid}</td>`;
                    bodyHtml += `<td class="rep-col-satcut" style="display: none;">${emp.SatCut}</td>`;

                    const remarkCellVal = getReportRemarksString(emp);
                    bodyHtml += `<td class="rep-col-remarks text-left" style="text-align: left;">${remarkCellVal}</td>`;
                    bodyHtml += "</tr>";
                });

                tableBody.innerHTML = bodyHtml;

                applyAllReportColumnToggles();
            }

            function getReportRemarksString(emp) {
                const parts = [];
                const includeJoinResign = document.getElementById("repRemJoinResign").checked;
                const includeOverride = document.getElementById("repRemOverride").checked;
                const includePair = document.getElementById("repRemPairs").checked;
                const includeSatEdit = document.getElementById("repRemSatEdit").checked;
                const includeCellSpecific = document.getElementById("repRemCellSpecific").checked;

                if (includeJoinResign && emp.JoinResignRemark) parts.push(emp.JoinResignRemark);
                if (includeOverride && emp.OverrideRemark) parts.push(emp.OverrideRemark);
                if (includePair && emp.LeavePairRemark) parts.push(emp.LeavePairRemark);
                if (includeSatEdit && emp.SaturdayRemark) parts.push(emp.SaturdayRemark);
                if (includeCellSpecific && emp.CellRemarks) parts.push(emp.CellRemarks);

                return parts.join("; ");
            }

            function toggleReportColumn(colClass, isChecked) {
                const cells = document.querySelectorAll(`.${colClass}`);
                cells.forEach(c => {
                    c.style.display = isChecked ? "" : "none";
                });
            }

            function applyAllReportColumnToggles() {
                toggleReportColumn("rep-col-sno", document.getElementById("repColSNo").checked);
                toggleReportColumn("rep-col-id", document.getElementById("repColID").checked);
                toggleReportColumn("rep-col-masterid", document.getElementById("repColMasterID").checked);
                toggleReportColumn("rep-col-name", document.getElementById("repColName").checked);
                toggleReportColumn("rep-col-present", document.getElementById("repColPresent").checked);
                toggleReportColumn("rep-col-final", document.getElementById("repColFinal").checked);
                toggleReportColumn("rep-col-paid", document.getElementById("repColPaid").checked);
                toggleReportColumn("rep-col-unpaid", document.getElementById("repColUnpaid").checked);
                toggleReportColumn("rep-col-satcut", document.getElementById("repColSatCut").checked);
                toggleReportColumn("rep-col-remarks", document.getElementById("repColRemarks").checked);
            }

            function rebuildReportRemarksColumn() {
                const rows = document.querySelectorAll("#reportTable tbody tr");
                if (rows.length === 0 || reportEmployeesData.length === 0) return;

                rows.forEach((row, i) => {
                    const emp = reportEmployeesData[i];
                    if (!emp) return;
                    const remarksCell = row.querySelector(".rep-col-remarks");
                    if (remarksCell) {
                        remarksCell.textContent = getReportRemarksString(emp);
                    }
                });
                showToast("Report remarks rebuilt.", "success");
            }

            function exportReportToExcel() {
                if (typeof XLSX === "undefined") {
                    showToast("Spreadsheet library is not loaded.", "error");
                    return;
                }

                const table = document.getElementById("reportTable");
                if (!table || reportEmployeesData.length === 0) {
                    showToast("No data available to export.", "warning");
                    return;
                }

                // Helper to decode HTML entities
                function decodeHTMLEntities(text) {
                    if (!text) return "";
                    const temp = document.createElement('div');
                    temp.innerHTML = text;
                    return temp.textContent || temp.innerText || "";
                }

                const title1 = decodeHTMLEntities(document.getElementById("repTitle1").textContent.trim());
                const title2 = decodeHTMLEntities(document.getElementById("repTitle2").textContent.trim());

                const AOA = [
                    [title1],
                    [title2]
                ];

                // 1. Write Header Column Names (filtering hidden columns)
                const headers = [];
                const headerCells = document.querySelectorAll("#reportTable thead tr th");
                headerCells.forEach(th => {
                    if (th.style.display !== "none") {
                        headers.push(decodeHTMLEntities(th.innerText.trim()));
                    }
                });
                AOA.push(headers);

                // 2. Write Data Rows (filtering hidden cells)
                const rows = document.querySelectorAll("#reportTable tbody tr");
                rows.forEach(tr => {
                    const rowVals = [];
                    const cells = tr.querySelectorAll("td");
                    cells.forEach(td => {
                        if (td.style.display !== "none") {
                            rowVals.push(decodeHTMLEntities(td.innerText.trim()));
                        }
                    });
                    AOA.push(rowVals);
                });

                // Write Worksheet
                const ws = XLSX.utils.aoa_to_sheet(AOA);
                const wb = XLSX.utils.book_new();

                // Set column widths based on visibility
                const colWidths = [];
                headerCells.forEach(th => {
                    if (th.style.display !== "none") {
                        const text = th.innerText.toLowerCase();
                        if (text.includes("name")) colWidths.push({ wch: 30 });
                        else if (text.includes("remark")) colWidths.push({ wch: 45 });
                        else if (text.includes("master")) colWidths.push({ wch: 15 });
                        else if (text.includes("days") || text.includes("present") || text.includes("total")) colWidths.push({ wch: 12 });
                        else colWidths.push({ wch: 8 });
                    }
                });
                ws["!cols"] = colWidths;

                // Merge titles dynamically across all visible columns
                const lastColIndex = headers.length - 1;
                ws["!merges"] = [
                    { s: { r: 0, c: 0 }, e: { r: 0, c: lastColIndex } },
                    { s: { r: 1, c: 0 }, e: { r: 1, c: lastColIndex } }
                ];

                // Apply formatting styles to cells in worksheet
                if (ws["A1"]) {
                    ws["A1"].s = {
                        font: { bold: true, name: "Calibri", sz: 11 },
                        alignment: { horizontal: "center", vertical: "center" }
                    };
                }
                if (ws["A2"]) {
                    ws["A2"].s = {
                        font: { bold: true, name: "Calibri", sz: 10 },
                        alignment: { horizontal: "center", vertical: "center" }
                    };
                }

                // Style headers row (AOA row index 2)
                const headerRowIdx = 2;
                for (let c = 0; c <= lastColIndex; c++) {
                    const cellRef = String.fromCharCode(65 + c) + (headerRowIdx + 1);
                    if (ws[cellRef]) {
                        ws[cellRef].s = {
                            font: { bold: true, name: "Calibri", sz: 10 },
                            fill: { fgColor: { rgb: "F2F2F2" } },
                            border: {
                                top: { style: "thin", color: { rgb: "D9D9D9" } },
                                bottom: { style: "thin", color: { rgb: "D9D9D9" } },
                                left: { style: "thin", color: { rgb: "D9D9D9" } },
                                right: { style: "thin", color: { rgb: "D9D9D9" } }
                            },
                            alignment: { horizontal: "center", vertical: "center" }
                        };
                    }
                }

                // Style data rows (AOA row index 3 onwards)
                const startDataRowIdx = 3;
                const endDataRowIdx = AOA.length - 1;
                for (let r = startDataRowIdx; r <= endDataRowIdx; r++) {
                    for (let c = 0; c <= lastColIndex; c++) {
                        const cellRef = String.fromCharCode(65 + c) + (r + 1);
                        if (ws[cellRef]) {
                            ws[cellRef].s = {
                                font: { name: "Calibri", sz: 10 },
                                border: {
                                    top: { style: "thin", color: { rgb: "E5E5E5" } },
                                    bottom: { style: "thin", color: { rgb: "E5E5E5" } },
                                    left: { style: "thin", color: { rgb: "E5E5E5" } },
                                    right: { style: "thin", color: { rgb: "E5E5E5" } }
                                },
                                alignment: {
                                    horizontal: (c === 0 || c === 1 || headers[c].toLowerCase().includes("days") || headers[c].toLowerCase().includes("total")) ? "center" : "left",
                                    vertical: "center"
                                }
                            };
                        }
                    }
                }

                XLSX.utils.book_append_sheet(wb, ws, "Attendance Report");

                const catVal = document.getElementById("repCategory").value;
                const monthSel = document.getElementById("repMonth");
                const mText = monthSel.options[monthSel.selectedIndex].text;
                const yearVal = document.getElementById("repYear").value;

                XLSX.writeFile(wb, `Attendance_Report_${mText}_${yearVal}_${catVal}.xlsx`);
                showToast("Downloaded Attendance Report Excel successfully!", "success");
            }
