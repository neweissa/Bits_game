class_name MissionData
extends RefCounted
## The three missions of each planet (ideas_del_juego.md, sections S2 and S6).
## Every mission uses one of a few templates, so changing a mission is changing
## data, not code:
##   "trivia" - a question from the Supabase table preguntas_juego (by id)
##   "risk"   - a risk from the Supabase table riesgos (by id): pick how to avoid it
##   "tune"   - short puzzle: move a dial (frequency, angle...) to the right value
##   "cipher" - short puzzle: an alien beacon in Caesar cipher (S4), find the shift
##   "choice" - a local question for rules that are not in the database yet
## If Supabase did not load (no config / no internet), the same rows are read from
## FALLBACK_QUESTIONS / FALLBACK_RISKS below, copied from the database.
## English: each mission has "<key>_en" texts, and the database rows used here
## are translated in EN_QUESTIONS / EN_RISKS (the database is in Spanish).
## Answer options are shuffled at random every time a mission opens, and the
## cipher of Draugr's second mission uses a random shift ("shift": -1).
## Random questions: trivia and risk missions with "temas" pick a random row of
## those topics from the database each time the planet's missions start (no
## repeats within a planet); question_id / risk_id is the fallback.

const PLANETS := [
	# 0 - Yuki / Villacaracas (Energía)
	[
		{"title": "Desplegar paneles solares", "title_en": "Deploy the solar panels", "type": "trivia", "question_id": 6, "temas": ["energia"]},
		{"title": "Elegir la batería certificada (UL)", "title_en": "Pick the certified (UL) battery", "type": "risk", "risk_id": 4, "temas": ["energia"],
			"prompt": "¿Qué haces con la batería?", "prompt_en": "What do you do with the battery?"},
		{"title": "Poner inhibidores para que los perros no se enciendan", "title_en": "Add inhibitors so the dogs stay off", "type": "trivia", "question_id": 8, "temas": ["energia"]},
	],
	# 1 - Zero (Propulsión + Orientación)
	[
		{"title": "Abrir una vela solar para moverse", "title_en": "Open a solar sail to move", "type": "trivia", "question_id": 9, "temas": ["propulsion", "orbitas"]},
		{"title": "Estabilizarse con giroscopios", "title_en": "Stabilize with gyroscopes", "type": "tune",
			"label": "Orientación de la nave", "label_en": "Ship attitude", "unit": "°", "start": 75, "target": 0, "step": 5, "min": -90, "max": 90,
			"instructions": "La nave da vueltas. Usa los giroscopios para dejarla en 0°.",
			"instructions_en": "The ship is spinning. Use the gyroscopes to bring it to 0°.",
			"explanation": "SwampSat usa giroscopios y ChargerSat-1 se estabiliza con la gravedad para no girar sin control.",
			"explanation_en": "SwampSat uses gyroscopes and ChargerSat-1 uses gravity to stop spinning out of control."},
		{"title": "Descartar tanques a presión", "title_en": "Drop the pressurized tanks", "type": "risk", "risk_id": 6, "temas": ["propulsion", "orbitas"],
			"prompt": "¿Qué haces con el motor y los tanques a presión?", "prompt_en": "What do you do with the engine and the pressurized tanks?"},
	],
	# 2 - Fernix (Térmico)
	[
		{"title": "Encontrar los bolsillos de aire atrapado", "title_en": "Find the trapped air pockets", "type": "risk", "risk_id": 13, "temas": ["termico"], "skip": [12],
			"prompt": "Ray encontró los bolsillos con infrarrojo. ¿Cómo se evita esto en la nave?",
			"prompt_en": "Ray found the pockets with infrared. How do you prevent this on the ship?"},
		{"title": "Limpiar la contaminación con horneado en vacío", "title_en": "Clean contamination with a vacuum bake-out", "type": "trivia", "question_id": 11, "temas": ["termico"]},
		{"title": "Elegir aluminio o acero", "title_en": "Choose aluminum or steel", "type": "trivia", "question_id": 12, "temas": ["termico"]},
	],
	# 3 - Draugr (Comunicaciones)
	[
		{"title": "Sintonizar una baliza en 437 MHz", "title_en": "Tune a beacon at 437 MHz", "type": "tune", "question_id": 13,
			"label": "Frecuencia de la radio", "label_en": "Radio frequency", "unit": " MHz", "start": 405, "target": 437, "step": 4, "min": 397, "max": 461,
			"instructions": "Hay mucho ruido. Busca la banda de 70 cm, donde transmiten las balizas de los CubeSats.",
			"instructions_en": "There is a lot of noise. Find the 70 cm band, where CubeSat beacons transmit."},
		{"title": "Calibrar la antena con el Sol, la Luna o una montaña", "title_en": "Calibrate the antenna with the Sun, the Moon or a mountain", "type": "cipher",
			"plain": "CALIBRA LA ANTENA CON EL SOL", "plain_en": "CALIBRATE THE ANTENNA WITH THE SUN", "shift": -1,
			"instructions": "Una baliza alien repite un mensaje cifrado. Corre las letras hasta que se lea.",
			"instructions_en": "An alien beacon repeats a coded message. Shift the letters until it reads.",
			"explanation": "Para calibrar una antena se apunta a algo cuya posición se conoce: el Sol, la Luna o una montaña. (Dato curioso: en radioaficionados nada puede ir cifrado, así que los aliens son \"ilegales\".)",
			"explanation_en": "To calibrate an antenna you point it at something whose position you know: the Sun, the Moon or a mountain. (Fun fact: amateur radio can't be encrypted, so the aliens are \"illegal\".)"},
		{"title": "Esperar 45 min antes de transmitir", "title_en": "Wait 45 min before transmitting", "type": "choice",
			"question": "Tu CubeSat acaba de salir del dispensador. ¿Cuándo puede empezar a transmitir?",
			"question_en": "Your CubeSat just left the deployer. When can it start transmitting?",
			"options": ["Después de 45 minutos", "De inmediato", "Después de 5 segundos", "Solo cuando aterrice"],
			"options_en": ["After 45 minutes", "Right away", "After 5 seconds", "Only when it lands"],
			"answer": "Después de 45 minutos", "answer_en": "After 45 minutes",
			"explanation": "Es una regla real del lanzamiento: hay que esperar 45 minutos antes de transmitir.",
			"explanation_en": "It is a real launch rule: you must wait 45 minutes before transmitting."},
	],
	# 4 - Control C (Riesgo / redundancia)
	[
		{"title": "Usar dos burn wires", "title_en": "Use two burn wires", "type": "trivia", "question_id": 19, "temas": ["riesgo", "costo", "desarrollo", "satelites"]},
		{"title": "Construir el clon (dos satélites)", "title_en": "Build the clone (two satellites)", "type": "risk", "risk_id": 21, "temas": ["riesgo"],
			"prompt": "¿Cómo te proteges de perder la nave?", "prompt_en": "How do you protect yourself from losing the ship?"},
		{"title": "No tocar el software después de la prueba final (DITL)", "title_en": "Don't touch the software after the final test (DITL)", "type": "risk", "risk_id": 16, "temas": ["riesgo"],
			"prompt": "¿Qué debes hacer?", "prompt_en": "What should you do?"},
	],
]

## Copy of the preguntas_juego rows used above (ids 6, 8, 9, 11, 12, 13, 19).
const FALLBACK_QUESTIONS := [
	{"id": 6, "tema": "energia", "pregunta": "¿Qué logran los paneles desplegables de ChargerSat-1?",
		"opciones": ["Casi duplicar la energía", "Triplicar la velocidad", "Enfriar la nave", "Nada"],
		"respuesta": "Casi duplicar la energía", "explicacion": "También mejoran la señal de su antena."},
	{"id": 8, "tema": "energia", "pregunta": "¿Qué hacen los interruptores de separación?",
		"opciones": ["Mantienen la nave apagada dentro del dispensador", "Abren la vela", "Calientan la batería", "Cambian la órbita"],
		"respuesta": "Mantienen la nave apagada dentro del dispensador", "explicacion": "Al salir al espacio se sueltan y la nave se enciende."},
	{"id": 9, "tema": "propulsion", "pregunta": "¿Qué tamaño tiene la vela de LightSail?",
		"opciones": ["32 m²", "3 m²", "320 m²", "1 m²"],
		"respuesta": "32 m²", "explicacion": "Se mueve con la radiación del Sol."},
	{"id": 11, "tema": "termico", "pregunta": "¿Para qué sirve el horneado en vacío térmico?",
		"opciones": ["Para que la nave suelte contaminantes antes del lanzamiento", "Para cocinar", "Para cargar baterías", "Para pintarla"],
		"respuesta": "Para que la nave suelte contaminantes antes del lanzamiento", "explicacion": "Se hace en casi todas las misiones."},
	{"id": 12, "tema": "termico", "pregunta": "¿Qué materiales se recomiendan para que la nave se queme al reentrar?",
		"opciones": ["Aluminio y acero", "Titanio y tungsteno", "Tantalio", "Cerámica"],
		"respuesta": "Aluminio y acero", "explicacion": "Los de alto punto de fusión pueden sobrevivir y causar daños."},
	{"id": 13, "tema": "comunicaciones", "pregunta": "¿Qué frecuencia tiene la banda de 70 cm?",
		"opciones": ["437 MHz", "140 MHz", "2,4 GHz", "88 MHz"],
		"respuesta": "437 MHz", "explicacion": "Hay muchos CubeSats con balizas fáciles de escuchar ahí."},
	{"id": 19, "tema": "riesgo", "pregunta": "¿Cuántos burn wires recomienda NASA?",
		"opciones": ["Dos separados", "Uno", "Ninguno", "Diez"],
		"respuesta": "Dos separados", "explicacion": "Reduce que algo se despliegue antes de tiempo."},
]

## Copy of the riesgos rows used above, plus a few more used as wrong answers.
const FALLBACK_RISKS := [
	{"id": 2, "nombre": "Despliegue antes de tiempo", "tema": "energia",
		"que_pasa": "El hilo que sujeta paneles o antenas se suelta durante la vibración o el ascenso.",
		"consecuencia": "Los lanzadores lo odian.", "como_evitarlo": "Usar dos burn wires separados."},
	{"id": 3, "nombre": "No cabe en el dispensador", "tema": "riesgo",
		"que_pasa": "Las medidas no cumplen las tolerancias.",
		"consecuencia": "Si no cabe, no vuela.", "como_evitarlo": "No diseñar al límite; salientes de máximo 6,5 mm."},
	{"id": 4, "nombre": "Batería sin certificación UL", "tema": "energia",
		"que_pasa": "Usas una batería sin certificar, casera o modificada.",
		"consecuencia": "El lanzador exige pruebas extra.", "como_evitarlo": "Usar baterías certificadas UL sin modificar."},
	{"id": 6, "nombre": "Llevar motor", "tema": "propulsion",
		"que_pasa": "La propulsión pone nerviosos al lanzador y a la carga principal.",
		"consecuencia": "Algunos no aceptan la nave; puede tardar más en conseguir lanzamiento.", "como_evitarlo": "Mantener el diseño simple."},
	{"id": 9, "nombre": "Estación terrena inadecuada", "tema": "comunicaciones",
		"que_pasa": "No puedes localizar, mandar órdenes ni bajar datos.",
		"consecuencia": "Es un \"asesino de misiones\".", "como_evitarlo": "Construirla temprano y probarla seguido."},
	{"id": 12, "nombre": "Piezas que sobreviven la reentrada", "tema": "termico",
		"que_pasa": "Materiales de alto punto de fusión (tantalio, titanio, tungsteno) no se queman al caer.",
		"consecuencia": "Amenaza a personas y propiedades; pueden exigirte un seguro.", "como_evitarlo": "Usar aluminio y acero."},
	{"id": 13, "nombre": "Aire atrapado", "tema": "termico",
		"que_pasa": "Al bajar la presión rápidamente, un bolsillo de aire podría reventar la estructura.",
		"consecuencia": "Peligro para el cohete y otras cargas.", "como_evitarlo": "Hacer un análisis de ventilación."},
	{"id": 14, "nombre": "Contaminación por desgasificación", "tema": "termico",
		"que_pasa": "Los materiales sueltan vapores en el vacío.",
		"consecuencia": "Pueden ensuciar partes sensibles y afectar la misión.", "como_evitarlo": "Horneado TVAC y materiales de baja desgasificación."},
	{"id": 16, "nombre": "Cambiar software después del DITL", "tema": "riesgo",
		"que_pasa": "Modificas el código después de la prueba DITL.",
		"consecuencia": "La prueba deja de valer y hay que repetirla.", "como_evitarlo": "No tocar el software después del DITL."},
	{"id": 19, "nombre": "Tu proyecto se atrasa", "tema": "riesgo",
		"que_pasa": "El cohete no espera a los CubeSats.",
		"consecuencia": "El cohete despega sin tu CubeSat.", "como_evitarlo": "Planificar con margen de tiempo."},
	{"id": 21, "nombre": "Falla del lanzamiento", "tema": "riesgo",
		"que_pasa": "Las fallas de lanzamiento siempre son posibles.",
		"consecuencia": "Pierdes la nave.", "como_evitarlo": "Es más barato construir dos satélites a la vez que uno y luego otro."},
]


## English versions of the database rows (same ids), with their topic ("tema").
const EN_QUESTIONS := {
	1: {"tema": "satelites", "pregunta": "How big is a 1U CubeSat?",
		"opciones": ["10 × 10 × 11 cm", "20 × 20 × 20 cm", "5 × 5 × 5 cm", "1 × 1 × 1 m"],
		"respuesta": "10 × 10 × 11 cm", "explicacion": "The basic unit is a 10 cm cube."},
	2: {"tema": "satelites", "pregunta": "What is the maximum mass of a 3U CubeSat?",
		"opciones": ["4.00 kg", "1.33 kg", "10 kg", "300 kg"],
		"respuesta": "4.00 kg", "explicacion": "According to the 3U acceptance checklist."},
	3: {"tema": "satelites", "pregunta": "In what year was the 6U size born?",
		"opciones": ["2014", "1999", "2005", "2020"],
		"respuesta": "2014", "explicacion": "It is like two 3Us side by side."},
	4: {"tema": "satelites", "pregunta": "How did Chasqui 1 get to space?",
		"opciones": ["A cosmonaut threw it by hand", "In a P-POD", "On a balloon", "On a plane"],
		"respuesta": "A cosmonaut threw it by hand", "explicacion": "It was during a spacewalk in 2014."},
	5: {"tema": "satelites", "pregunta": "What was the first CubeSat from an elementary school?",
		"opciones": ["STMSat-1", "KickSat", "Dellingr", "GRIFEX"],
		"respuesta": "STMSat-1", "explicacion": "From St. Thomas More Cathedral School."},
	6: {"tema": "energia", "pregunta": "What do ChargerSat-1's deployable panels achieve?",
		"opciones": ["Almost double the power", "Triple the speed", "Cool the ship", "Nothing"],
		"respuesta": "Almost double the power", "explicacion": "They also improve its antenna signal."},
	7: {"tema": "energia", "pregunta": "What happens if you use a battery without UL certification?",
		"opciones": ["They ask for extra tests", "Nothing", "They give you another one", "You fly sooner"],
		"respuesta": "They ask for extra tests", "explicacion": "The launch provider requires proof that it is robust."},
	8: {"tema": "energia", "pregunta": "What do separation switches do?",
		"opciones": ["Keep the ship off inside the deployer", "Open the sail", "Heat the battery", "Change the orbit"],
		"respuesta": "Keep the ship off inside the deployer", "explicacion": "Once in space they release and the ship turns on."},
	9: {"tema": "propulsion", "pregunta": "How big is LightSail's sail?",
		"opciones": ["32 m²", "3 m²", "320 m²", "1 m²"],
		"respuesta": "32 m²", "explicacion": "It moves with the Sun's radiation."},
	10: {"tema": "propulsion", "pregunta": "Why can carrying an engine delay your launch?",
		"opciones": ["It makes the rocket and its main payload nervous", "It is too heavy", "It is illegal", "It drains the battery"],
		"respuesta": "It makes the rocket and its main payload nervous", "explicacion": "Some launch providers don't accept CubeSats with propulsion."},
	11: {"tema": "termico", "pregunta": "What is a thermal vacuum bake-out for?",
		"opciones": ["So the ship releases contaminants before launch", "To cook", "To charge batteries", "To paint it"],
		"respuesta": "So the ship releases contaminants before launch", "explicacion": "Almost every mission does it."},
	12: {"tema": "termico", "pregunta": "Which materials are recommended so the ship burns up on reentry?",
		"opciones": ["Aluminum and steel", "Titanium and tungsten", "Tantalum", "Ceramic"],
		"respuesta": "Aluminum and steel", "explicacion": "High melting point materials can survive and cause damage."},
	13: {"tema": "comunicaciones", "pregunta": "What frequency is the 70 cm band?",
		"opciones": ["437 MHz", "140 MHz", "2.4 GHz", "88 MHz"],
		"respuesta": "437 MHz", "explicacion": "Many CubeSats have easy-to-hear beacons there."},
	14: {"tema": "comunicaciones", "pregunta": "What is considered a \"mission killer\"?",
		"opciones": ["Launching with an inadequate ground station", "Painting the ship", "Using two burn wires", "Having panels"],
		"respuesta": "Launching with an inadequate ground station", "explicacion": "Test the station early and often."},
	15: {"tema": "comunicaciones", "pregunta": "What is the minimum number of days the FCC takes to grant an experimental license?",
		"opciones": ["90", "7", "365", "30"],
		"respuesta": "90", "explicacion": "That's why you should apply as soon as possible."},
	16: {"tema": "costo", "pregunta": "Up to how much does NASA pay for the launch through CSLI?",
		"opciones": ["300,000 USD", "1 million USD", "30,000 USD", "100 million USD"],
		"respuesta": "300,000 USD", "explicacion": "It is usually enough for a 3U to low orbit."},
	17: {"tema": "costo", "pregunta": "What minimum share of the budget should be saved for surprises?",
		"opciones": ["10%", "1%", "50%", "0%"],
		"respuesta": "10%", "explicacion": "That covers unexpected events."},
	18: {"tema": "costo", "pregunta": "How much did LightSail-2 raise with crowdfunding?",
		"opciones": ["More than 1.24 million USD", "10,000 USD", "100 million USD", "Nothing"],
		"respuesta": "More than 1.24 million USD", "explicacion": "According to Kickstarter."},
	19: {"tema": "riesgo", "pregunta": "How many burn wires does NASA recommend?",
		"opciones": ["Two separate ones", "One", "None", "Ten"],
		"respuesta": "Two separate ones", "explicacion": "It lowers the chance of something deploying too early."},
	20: {"tema": "riesgo", "pregunta": "How far can parts stick out from the CubeSat body?",
		"opciones": ["6.5 mm", "65 mm", "0 mm", "1 m"],
		"respuesta": "6.5 mm", "explicacion": "If it doesn't fit, it doesn't fly."},
	21: {"tema": "orbitas", "pregunta": "Which of these orbits does NASA Goddard's MDL design?",
		"opciones": ["Lunar", "None", "Only LEO", "Only GEO"],
		"respuesta": "Lunar", "explicacion": "Also LEO, GEO, libration, retrograde, drift-away and deep space."},
	22: {"tema": "desarrollo", "pregunta": "How long does it usually take to build a CubeSat?",
		"opciones": ["18 to 24 months", "1 week", "10 years", "2 days"],
		"respuesta": "18 to 24 months", "explicacion": "It can be done in just 9 months."},
	23: {"tema": "desarrollo", "pregunta": "How many days does an MDL point design study take?",
		"opciones": ["6 days", "1 hour", "1 year", "30 days"],
		"respuesta": "6 days", "explicacion": "It delivers CAD, an equipment list and a CEMA cost."},
	24: {"tema": "riesgo", "pregunta": "What is level 1 of concept maturity (CML) called?",
		"opciones": ["Cocktail Napkin", "Point design", "Launch", "Prototype"],
		"respuesta": "Cocktail Napkin", "explicacion": "It is the mission's very first idea."},
}
const EN_RISKS := {
	1: {"tema": "riesgo", "nombre": "Something breaks in vibration", "que_pasa": "With a new design something will almost surely break, usually in vibration or shock tests.",
		"consecuencia": "If you fix something inside, you'll have to repeat tests.", "como_evitarlo": "Put important parts near the outside so they are easy to repair."},
	2: {"tema": "energia", "nombre": "Early deployment", "que_pasa": "The wire holding panels or antennas lets go during vibration or ascent.",
		"consecuencia": "Launch providers hate it.", "como_evitarlo": "Use two separate burn wires."},
	3: {"tema": "riesgo", "nombre": "It doesn't fit in the deployer", "que_pasa": "The measurements are out of tolerance.",
		"consecuencia": "If it doesn't fit, it doesn't fly.", "como_evitarlo": "Don't design at the limit; bumps of 6.5 mm max."},
	4: {"tema": "energia", "nombre": "Battery without UL certification", "que_pasa": "You use an uncertified, homemade or modified battery.",
		"consecuencia": "The launch provider asks for extra tests.", "como_evitarlo": "Use UL-certified, unmodified batteries."},
	5: {"tema": "riesgo", "nombre": "New parts with no flight history", "que_pasa": "Batteries, antennas or ADCS that have never flown.",
		"consecuencia": "More risk of failure and less trust from the launch provider.", "como_evitarlo": "Choose parts that have already flown on CubeSats."},
	6: {"tema": "propulsion", "nombre": "Carrying an engine", "que_pasa": "Propulsion makes the launcher and the main payload nervous.",
		"consecuencia": "Some won't accept the ship; getting a launch can take longer.", "como_evitarlo": "Keep the design simple."},
	7: {"tema": "costo", "nombre": "Running out of money", "que_pasa": "You can't finish the CubeSat after NASA started spending on your launch.",
		"consecuencia": "The launch is lost, other CubeSats could be left out and you'd have to repay NASA.", "como_evitarlo": "Don't accept a launch until you're sure you can deliver on time."},
	8: {"tema": "comunicaciones", "nombre": "Late license", "que_pasa": "The license doesn't arrive before delivery. One CubeSat got its FCC license just days before launch.",
		"consecuencia": "You're taken off the launch and could lose the CubeSat.", "como_evitarlo": "Send the complete application within 30 days of being assigned (or sooner)."},
	9: {"tema": "comunicaciones", "nombre": "Inadequate ground station", "que_pasa": "You can't track it, send commands or download data.",
		"consecuencia": "It is a \"mission killer\".", "como_evitarlo": "Build it early and test it often."},
	10: {"tema": "riesgo", "nombre": "The team's knowledge is lost", "que_pasa": "Students graduate and leave.",
		"consecuencia": "You have to \"reinvent the wheel\".", "como_evitarlo": "Keep records and photos of everything."},
	11: {"tema": "riesgo", "nombre": "Mass out of tolerance", "que_pasa": "The final mass doesn't match what the launch provider calculated.",
		"consecuencia": "You can be taken off the launch.", "como_evitarlo": "Use large but reasonable margins in your estimates."},
	12: {"tema": "termico", "nombre": "Parts that survive reentry", "que_pasa": "High melting point materials (tantalum, titanium, tungsten) don't burn up.",
		"consecuencia": "A threat to people and property; you may need insurance.", "como_evitarlo": "Use aluminum and steel."},
	13: {"tema": "termico", "nombre": "Trapped air", "que_pasa": "When pressure drops fast, an air pocket could burst the structure.",
		"consecuencia": "Danger for the rocket and other payloads.", "como_evitarlo": "Do a venting analysis."},
	14: {"tema": "termico", "nombre": "Outgassing contamination", "que_pasa": "Materials release vapors in vacuum.",
		"consecuencia": "They can dirty sensitive parts and hurt the mission.", "como_evitarlo": "TVAC bake-out and low-outgassing materials."},
	15: {"tema": "termico", "nombre": "Broken solder joints or a melted battery", "que_pasa": "Temperature changes in orbit damage the ship.",
		"consecuencia": "The mission can fail.", "como_evitarlo": "Do TVAC cycling (optional)."},
	16: {"tema": "riesgo", "nombre": "Changing software after the DITL", "que_pasa": "You change the code after the DITL test.",
		"consecuencia": "The test no longer counts and must be repeated.", "como_evitarlo": "Don't touch the software after the DITL."},
	17: {"tema": "riesgo", "nombre": "Touching the hardware after vibration", "que_pasa": "You remove panels or screws, or release deployables.",
		"consecuencia": "The test no longer counts and must be repeated.", "como_evitarlo": "Don't make physical changes after the test."},
	18: {"tema": "riesgo", "nombre": "Tests without integrator review", "que_pasa": "Something was missing in the test procedures.",
		"consecuencia": "You might repeat the tests.", "como_evitarlo": "Send the procedures before testing."},
	19: {"tema": "riesgo", "nombre": "Your project falls behind", "que_pasa": "The rocket doesn't wait for CubeSats.",
		"consecuencia": "The rocket launches without your CubeSat.", "como_evitarlo": "Plan with time to spare."},
	20: {"tema": "riesgo", "nombre": "Launch day is scrubbed", "que_pasa": "Delays for weather and other reasons are common.",
		"consecuencia": "You wait longer.", "como_evitarlo": "If you travel, book extra days."},
	21: {"tema": "riesgo", "nombre": "Launch failure", "que_pasa": "Launch failures are always possible.",
		"consecuencia": "You lose the ship.", "como_evitarlo": "It is cheaper to build two satellites at once than one after the other."},
	22: {"tema": "comunicaciones", "nombre": "You don't know which satellite is yours", "que_pasa": "After launch you must find out which object is yours.",
		"consecuencia": "It can take several weeks.", "como_evitarlo": "Onboard GPS, TLEs and help from radio amateurs."},
	23: {"tema": "riesgo", "nombre": "Incomplete proposal", "que_pasa": "It doesn't follow the call's instructions.",
		"consecuencia": "It's left out that year.", "como_evitarlo": "Follow the instructions and include everything requested."},
	24: {"tema": "orbitas", "nombre": "Rigid launch requirements", "que_pasa": "Asking for a very specific orbit or date.",
		"consecuencia": "You wait longer for a launch.", "como_evitarlo": "Keep requirements as flexible as possible."},
}
## Rows that are not real risks to avoid (no consequence in the database).
const SKIP_RISKS := [25, 26]
## Picked question/risk id for each mission of the current planet ("chapter:index").
static var _picks: Dictionary = {}


static func titles(chapter: int) -> Array:
	return PLANETS[chapter].map(func(m): return GameData.txt(m, "title"))


static func count(chapter: int) -> int:
	return PLANETS[chapter].size()


## The mission ready to show: {title, type, question, options, answer, explanation,
## source, ...}. Options are already shuffled (a new order every time).
static func build(chapter: int, index: int) -> Dictionary:
	var mission: Dictionary = _localized(PLANETS[chapter][index])
	var rng := _random()
	var english := GameData.lang == "en"
	match mission.type:
		"trivia":
			var row := _question(int(_picks.get("%d:%d" % [chapter, index], mission.question_id)))
			mission.question = row.pregunta
			mission.options = Array(row.opciones).duplicate()
			mission.answer = row.respuesta
			mission.explanation = row.explicacion
			mission.source = "Supabase: preguntas_juego #%d" % row.id + (" (translated)" if english else "")
			if mission.has("temas"):
				mission.source += GameData.t("  ·  pregunta al azar del tema", "  ·  random question on the topic")
		"risk":
			var risk_id := int(_picks.get("%d:%d" % [chapter, index], mission.risk_id))
			var risk := _risk(risk_id)
			if risk_id != int(mission.risk_id):
				# A random risk: the planet-specific prompt would not fit.
				mission.prompt = GameData.t("¿Cómo lo evitas?", "How do you avoid it?")
			mission.question = GameData.t("Riesgo: %s\n%s\n%s", "Risk: %s\n%s\n%s") % [risk.nombre, risk.que_pasa, mission.prompt]
			mission.answer = risk.como_evitarlo
			mission.options = [risk.como_evitarlo] + _wrong_fixes(risk, 2)
			mission.explanation = GameData.t("Si no lo evitas: ", "If you don't avoid it: ") + str(risk.consecuencia)
			mission.source = "Supabase: riesgos #%d" % risk.id + (" (translated)" if english else "")
		"tune":
			if mission.has("question_id"):
				var row := _question(mission.question_id)
				mission.explanation = "%s: %s" % [row.respuesta, row.explicacion]
				mission.source = "Supabase: preguntas_juego #%d" % row.id + (" (translated)" if english else "")
			else:
				mission.source = "ideas_del_juego.md"
		"cipher":
			# A new shift every time (1..25), so the answer is never the same.
			if int(mission.shift) <= 0:
				mission.shift = rng.randi_range(1, 25)
			mission.encrypted = caesar(mission.plain, mission.shift)
			mission.source = "ideas_del_juego.md (S4)"
		"choice":
			mission.options = Array(mission.options).duplicate()
			mission.source = "ideas_del_juego.md"
	if mission.has("options"):
		_shuffle(mission.options, rng)
	return mission


static var _rng: RandomNumberGenerator = null


## One generator for the whole game, seeded from the clock once (planet.gd
## seeds the global one on purpose, so it is not used here).
static func _random() -> RandomNumberGenerator:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.randomize()
	return _rng


## Shifts letters A-Z by `shift` places (negative to decode).
static func caesar(text: String, shift: int) -> String:
	var out := ""
	for c in text:
		var code := c.unicode_at(0)
		if code >= 65 and code <= 90:
			out += String.chr(65 + posmod(code - 65 + shift, 26))
		else:
			out += c
	return out


# --- data lookup ----------------------------------------------------------------

## Chooses, at random, the question or risk of every mission of a planet,
## without repeating one inside the planet. Called when its missions start.
static func new_run(chapter: int) -> void:
	var rng := _random()
	var used_questions: Array = []
	var used_risks: Array = []
	for index in count(chapter):
		var mission: Dictionary = PLANETS[chapter][index]
		if not mission.has("temas"):
			continue
		var temas: Array = mission.temas
		var key := "%d:%d" % [chapter, index]
		_picks.erase(key)
		if mission.type == "trivia":
			var ids := _question_ids(temas).filter(func(id): return not used_questions.has(id))
			if not ids.is_empty():
				_picks[key] = ids[rng.randi() % ids.size()]
				used_questions.append(_picks[key])
		elif mission.type == "risk":
			var skip: Array = mission.get("skip", [])
			var ids := _risk_ids(temas).filter(func(id): return not used_risks.has(id) and not skip.has(id))
			if not ids.is_empty():
				_picks[key] = ids[rng.randi() % ids.size()]
				used_risks.append(_picks[key])


## Ids of the questions about any of `temas` (English: only translated ones).
static func _question_ids(temas: Array) -> Array:
	var ids := []
	if GameData.lang == "en":
		for id in EN_QUESTIONS:
			if temas.has(EN_QUESTIONS[id].tema):
				ids.append(int(id))
		return ids
	var rows: Array = GameData.questions if not GameData.questions.is_empty() else FALLBACK_QUESTIONS
	for row in rows:
		if temas.has(str(row.get("tema", ""))):
			ids.append(int(row.id))
	return ids


static func _risk_ids(temas: Array) -> Array:
	var ids := []
	for row in _all_risks():
		if temas.has(str(row.get("tema", ""))) and not SKIP_RISKS.has(int(row.id)):
			ids.append(int(row.id))
	return ids


## Copy of a mission with its "_en" texts in place when the game is in English.
static func _localized(source: Dictionary) -> Dictionary:
	var mission: Dictionary = source.duplicate(true)
	if GameData.lang == "en":
		for key in source.keys():
			if str(key).ends_with("_en"):
				mission[str(key).trim_suffix("_en")] = source[key]
	return mission


static func _question(id: int) -> Dictionary:
	if GameData.lang == "en" and EN_QUESTIONS.has(id):
		var row: Dictionary = EN_QUESTIONS[id].duplicate(true)
		row["id"] = id
		return row
	for row in GameData.questions:
		if int(row.get("id", -1)) == id:
			return row
	for row in FALLBACK_QUESTIONS:
		if row.id == id:
			return row
	push_error("MissionData: pregunta %d no existe" % id)
	return {"id": id, "pregunta": "?", "opciones": ["?"], "respuesta": "?", "explicacion": ""}


static func _risk(id: int) -> Dictionary:
	for row in _all_risks():
		if int(row.get("id", -1)) == id:
			return row
	push_error("MissionData: riesgo %d no existe" % id)
	return {"id": id, "nombre": "?", "que_pasa": "", "consecuencia": "", "como_evitarlo": "?"}


static func _all_risks() -> Array:
	if GameData.lang == "en":
		var rows := []
		for id in EN_RISKS:
			var en: Dictionary = EN_RISKS[id].duplicate(true)
			en["id"] = id
			rows.append(en)
		return rows
	return GameData.risks if not GameData.risks.is_empty() else FALLBACK_RISKS


## How-to-avoid texts of other risks, used as wrong answers.
static func _wrong_fixes(risk: Dictionary, amount: int) -> Array:
	var others := _all_risks().filter(func(r):
		return int(r.id) != int(risk.id) and r.como_evitarlo != risk.como_evitarlo and r.tema != risk.tema \
			and not SKIP_RISKS.has(int(r.id)))
	# Same picks every time for the same risk.
	others.sort_custom(func(a, b): return (int(a.id) * 7 + int(risk.id) * 13) % 29 < (int(b.id) * 7 + int(risk.id) * 13) % 29)
	return others.slice(0, amount).map(func(r): return r.como_evitarlo)


static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = items[i]
		items[i] = items[j]
		items[j] = tmp
