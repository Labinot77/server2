<script>
    import AppWrapper from "../components/AppWrapper.svelte";

    const Operators = ['+', '-', '*', '÷'];

    let DisplayElement;
    let Display = '';
    let History = [];

    const UpdateDisplayRatio = () => {
        const ratio = Math.min(1, 4 / Display.length);
        DisplayElement.style.transform = `scale(${ratio})`;
    };

    const HasOperator = () => {
        return History.some(val => Operators.includes(val));
    };

    const AddValue = (Key) => {
        const LastEntry = History[History.length - 1];
        if (LastEntry && !isNaN(LastEntry) && (LastEntry !== '.' || Key !== '.') && !Operators.includes(Key)) {
            History[History.length - 1] = LastEntry + Key;
        } else {
            if (Operators.includes(Key) && Operators.includes(LastEntry)) return; // don't allow multiple operators in a row. (It won't break it if disabled, but its just ugly.)
            if (Key != "-" && Operators.includes(Key) && !LastEntry) return; // never should be able to start with a operator.
            if (Key === '.' && (!LastEntry || isNaN(LastEntry))) History.push('0'); // if Key is a decimal, but there's no number in front of it - add it.
            History.push(Key);
        };

        Display = History.join('');
        UpdateDisplayRatio();
    };

    const CalculateResult = () => {
        let Expression = History.join('');
        if (Operators.includes(Expression.slice(-1))) {
            Expression = Expression.slice(0, -1);
        };

        let currentOperator = '+';
        let currentNumber = '';
        let result = 0;

        for (let i = 0; i < History.length; i++) {
            const currentChar = History[i];

            if (!isNaN(currentChar) || currentChar === '.') {
                currentNumber += currentChar;
            };

            if (Operators.includes(currentChar) || i === History.length - 1) {
                if (currentNumber) {
                    const parsedNumber = parseFloat(currentNumber);
                    if (currentOperator === '+') {
                        result += parsedNumber;
                    } else if (currentOperator === '-') {
                        result -= parsedNumber;
                    } else if (currentOperator === '*') {
                        result *= parsedNumber;
                    } else if (currentOperator === '÷') {
                        result /= parsedNumber;
                    };
                };

                currentNumber = '';
                currentOperator = currentChar;
            };
        };

        const FormattedResult = result.toString();
        const DecimalPlaces = FormattedResult.split('.')[1]?.length || 0;
        return DecimalPlaces > 0 ? (DecimalPlaces > 4 ? result.toFixed(4) : result.toFixed(DecimalPlaces)) : parseInt(result);
    };

    const ButtonPress = Key => {
        const LastEntry = History[History.length - 1];

        if (LastEntry && History.length == 1 && LastEntry == 0) {
            History = [];
        }

        switch (Key) {
            case "AC":
                History = [];
                Display = '';
                UpdateDisplayRatio();
                break;
            case "+/-":
                if (!LastEntry || isNaN(LastEntry)) return; // if the last entry is not a number, do nothing
                const InverseValue = -parseFloat(LastEntry);
                History[History.length - 1] = InverseValue.toString();
                Display = History.join('');
                UpdateDisplayRatio();
                break;
            case "%":
                if (!LastEntry || isNaN(LastEntry)) return;

                const Percentage = parseFloat(LastEntry) / 100;
                History[History.length - 1] = Percentage.toString();
                Display = History.join('');
                UpdateDisplayRatio();
                break;
            case "=":
                if (!HasOperator()) return;
                const Value = CalculateResult();
                History = [Value.toString()];
                Display = Value.toString();
                UpdateDisplayRatio();
                break;
            default:
                AddValue(Key);
                break;
        }
    };

    const RemoveLastDigit = Event => {
        if (Event.key != 'Backspace') return;

        const LastEntry = History[History.length - 1];
        if (!LastEntry) return;

        if (LastEntry.length === 1) {
            History.pop();
        } else {
            History[History.length - 1] = LastEntry.slice(0, -1);
        };

        Display = History.join('');
        UpdateDisplayRatio();
    }
</script>

<AppWrapper style="background-color: black">
    <div class="calculator" on:keydown={RemoveLastDigit}>
        <div class="calculator-display">
            <div bind:this={DisplayElement} class="auto-scaling-text">{Display}</div>
        </div>
        <div class="calculator-keypad">
            <div class="input-keys">
                <div class="function-keys">
                    <button on:click={() => { ButtonPress("AC")}} class="calculator-key key-clear">AC</button>
                    <button on:click={() => { ButtonPress("+/-")}} class="calculator-key key-sign">±</button>
                    <button on:click={() => { ButtonPress("%")}} class="calculator-key key-percent">%</button>
                </div>
                <div class="digit-keys">
                    <button on:click={() => { ButtonPress("0")}} class="calculator-key key-0">0</button>
                    <button on:click={() => { ButtonPress(".")}} class="calculator-key key-dot">●</button>
                    <button on:click={() => { ButtonPress("1")}} class="calculator-key key-1">1</button>
                    <button on:click={() => { ButtonPress("2")}} class="calculator-key key-2">2</button>
                    <button on:click={() => { ButtonPress("3")}} class="calculator-key key-3">3</button>
                    <button on:click={() => { ButtonPress("4")}} class="calculator-key key-4">4</button>
                    <button on:click={() => { ButtonPress("5")}} class="calculator-key key-5">5</button>
                    <button on:click={() => { ButtonPress("6")}} class="calculator-key key-6">6</button>
                    <button on:click={() => { ButtonPress("7")}} class="calculator-key key-7">7</button>
                    <button on:click={() => { ButtonPress("8")}} class="calculator-key key-8">8</button>
                    <button on:click={() => { ButtonPress("9")}} class="calculator-key key-9">9</button>
                </div>
            </div>
            <div class="operator-keys">
                <button on:click={() => { ButtonPress("÷")}} class="calculator-key key-divide">÷</button>
                <button on:click={() => { ButtonPress("*")}} class="calculator-key key-multiply">*</button>
                <button on:click={() => { ButtonPress("-")}} class="calculator-key key-subtract">-</button>
                <button on:click={() => { ButtonPress("+")}} class="calculator-key key-add">+</button>
                <button on:click={() => { ButtonPress("=")}} class="calculator-key key-equals">=</button>
            </div>
        </div>
    </div>
</AppWrapper>

<style>
    .calculator {
        position: absolute;
        inset: 5vh 0 2.4vh;
        display: flex;
        flex-direction: column;
        padding: 0 1.2vh;
    }

    .calculator-display {
        position: relative;
        flex: 1;
        font-size: 6vh;
        font-weight: 300;
        white-space: nowrap;
    }

    .calculator-display .auto-scaling-text {
        position: absolute;
        right: 0.8vh;
        bottom: 0.6vh;
        transform-origin: right;
    }

    .calculator-keypad { display: flex; }
    .input-keys { width: 75%; }
    .function-keys, .digit-keys { display: flex; flex-wrap: wrap; }
    .digit-keys { flex-wrap: wrap-reverse; }
    .operator-keys { flex: 1; display: flex; flex-direction: column; }

    .calculator-key {
        width: calc(33.333% - 1.2vh);
        height: 5.4vh;
        margin: 0.6vh;
        padding: 0;
        border: none;
        outline: none;
        border-radius: 2.7vh;
        background: #333336;
        color: white;
        font-family: inherit;
        font-size: 2.4vh;
        cursor: pointer;
        user-select: none;
        transition: filter 100ms;
    }

    .calculator-key:hover { filter: brightness(1.25); }
    .calculator-key:active { filter: brightness(1.5); }

    .function-keys .calculator-key { background: #a5a5a5; color: black; }
    .key-0 { width: calc(66.666% - 1.2vh); text-align: left; padding-left: 2.1vh; }
    .key-dot { font-size: 1vh; }
    .operator-keys .calculator-key { width: calc(100% - 1.2vh); background: var(--phone-orange); font-size: 2.8vh; }
</style>
