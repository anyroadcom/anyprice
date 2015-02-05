> This is taken from [#646](https://github.com/anyroadcom/anyroad/issues/646) of [anyroadcom/anyroad](https://github.com/anyroadcom/anyroad). Proper README.md coming soon.

## Abstract
On this issue we describe what is currently happening with the pricing definition and we propose a new solution for it.

## Current Implementation

### Base Pricing Definition for Tour
The Tour model provides an attribute for storing the _base_ price (`price_cents`) for the tour and another attribute (`pricing_type`) that is used for defining if the charge for a tour is calculated on a _per person_, _per tour_ basis or it handled by _custom_ pricing rules. It also provides an attribute for handling the deposit of the tour (`deposit_cents`), if applicable. Also the Tour model is responsible for storing currency information. This is our _base_ currency. All of these attributes are used by the calculator.

### Custom Pricing Definition for Tour
If the tour has _custom_ pricing, then the _base_ price definition is totally ignored (except for the deposit and the currency). The custom pricing is handled by the `CustomPricing` model and what it does, is to allow us to have flexibility when it comes to different cases for number of people that are taking the tour. So, for example, we could setup our rules so that for 1 up to 4 people the price for a tour is calculated in a_per person_ basis, and for 5+ people the price is calculated on a _per tour_ basis. For our reference, a `CustomPricing` instance looks like this:

```ruby
id: 307, tour_id: 5159, range: "(4+)", position: 2, price_type: 0, price_cents: 2800
```
### Price Addons for Tour
We also provide a way for allowing guides to include some extras to their tours for an additional cost. This logic for this is handled by the `PriceAddon` model and when it comes to pricing type, things are pretty similar with the `Tour` and `CustomPricing` model: an addon could be charged either _per person_ or _per tour_. The `PriceAddon` model holds information about the price of the addon, but everything else (currency, deposit) is handled by the `Tour` or the `CustomPricing` model.

### Limitations of this approach
At first, there is a lot of duplication going on here. The logic behind the pricing type (per person or per tour) appears on every model that has to do with pricing: `Tour`, `CustomPricing`  and `PriceAddon`. This is not the best way to go ([code smell](http://en.wikipedia.org/wiki/Code_smell)).

At the same time, while we provide some kind of flexibility when it comes to price definition (via the `CustomPricing`, we do not provide any kind of flexibility for other properties of the pricing in general, such as the `deposit` for example. `CustomPricing` definitions do not have this ability.

Finally, this implementation is somehow hard to extend and maintain because everything is so coupled that lot of changes need to happen at two (at least) parts of the code. So, for example, if we wante to introduce something like a _Seasonal Pricing_ we would have to do it for all `Tour`, `CustomPricing`, but for `PriceAddon`. 

## New Proposed Implementation
We saw earlier that the _base_ pricing definition for a `Tour` could be achieved by using logic similar to the one implemented for `CustomPricing` model. The way to do it is to create a pricing definition that would look like this:

```javascript
  "1+" => { type: :participant, price: { adult: 1000, children: 900 }, deposit: 300 }
```

What this means is that for 1 or more guests we charge or a per person basis. As you see we can easily extend the definition and add attributes for different types of participants. This way we can extend the definition and include different prices for people with disabilities, or even cover cases for tours that allow you to bring your pet onboard.

According to our new specs, we need to have definitions like this for multiple models, so it would nice to have only *one* model do the job and everything else to associate with it. This model is going to be called `PricingDefinition` and will under the `Pricing` module. All models that will relate to it will be the models we called `priceable` on #644.

### An outline for `PriceDefinition`
The requirements for the `PriceDefinition` model are the following:

* it should hold information about pricing definitions
* it should hold information about the type of priceable (e.g. primary, secondary)
* it should save definitions in a flexible, yet maintainable way (serialization)
* it should validate definitions' structure (schema validation)
* it should validate definitions in terms of logic (keep reading)
* it should validate definitions against the capacity of the priceable resource 
* it should be shared between classes that need pricing definitions (polymorphism)
* it should related to an interval if needed
* it should validate that definitions belonging to a resource don't overlap

```ruby
# dummy code
module Pricing
  class Definition
    attr :definitions, :json, default: {}
    attr :interval_begin, :date, default: nil
    attr :interval_end, :date, default: :nil
    attr :priceable_type, :string, default: :nil
    attr :priceable_id, :integer, default: :nil
    belongs_to :priceable, polymorphic: true
  end
end
```

### Pricing Definition schema
As we said earlier we need to store definitions in a flexible and maintainable way, but first we need to define how this information will look like. The proposed structure is pretty similar to what we have for `CustomPricing` and for the majority of our tour is could work like this:

```javascript
{
  "1+" => { type: :participant, price: { adult: 1000, children: 900 }, deposit: 300 }
}
```
The key represents the number of people for which this definition should apply. We could consider it as our way of defining ranges in a similar way that Ruby does. This means that if one or more people want to take this tour, the total cost should be calculated per person and it's `$10,00` for adults, `$9,00` for children and a deposit of `$3` per person is required.

Things could get as complicated as we like. Imagine the following definition:

```javascript
{
  "1..3" => { type: :person, price: { adult: 1000, children: 900 }, deposit: 0 },
  "4..9" => { type: :person, price: { adult: 800, children: 700 }, deposit: 250 },
  "10+" => { type: :item, price: { item: 6000 }, deposit: 2000 }
}
```

This would translate to:
* for 1 up to 3 people, charge `$10,00` for adults, `$9,00`for children, no deposit required
* for 1 up to 9 people, charge `$8,00` for adults, `$7,00` for children, the deposit is `$2,5` per person
* for 10+ people charge `$60,00`, the deposit is `$20,00`

### Seasonal Pricing Definitions
For every priceable resource in our application, we should be able to define multiple definitions accross different intervals. This are going to be called _Seasonal Pricings_ from now on. The kind of behavior we need for this includes:

* priceable resources must have a `default` definition without interval
* the `default` definition cannot be deleted
* priceables resource should have an unlimited amount of seasonal definitions
* seasonal definitions should not overlap
* seasonal definitions could have completely different definition schemas

### Validations
Since this model is the backbone of our pricing system we must make sure that we fuck the shit out of it when it comes to validations. We will separate the validations in two different contexts: the definition itself and all the rest.

### Definition schema validations

Definition should comply with  the json schema:

```ruby
{
  "<range>" => { 
    type: "[participant|one_off]",
    price: { "<type>" => Integer }, # price: { "<type>" => { participant_type_a: Integer, ...  } }
    deposit: Integer
  }
}
```

Definition keys (ranges) should not overlap

```ruby
# Invalid sequence: missing definition for exactly 3 people
{ "1..3" => { ... }, "4..9" => { .. } }

# Invalid sequence: multiple definitions for 4 people
{ "1..4" => { .. }, "4+" => { .. } }
```
Definition should comply to the mix/max capacity of the priceable

```ruby
# pricable.min => 4, priceable.max => 20
# Invalid sequence: lower definition out of range
{ "1..3" => { ... }, "4+" => { ... } }

# Invalid sequence: upper definition out of range
{ "1..3" => { ... }, "4..21" => { ... } }
```

### Interval validations

Pricing definitions with intervals for a priceable resource should not overlap. To be more specific:

* the beginning of the interval for a pricing definition cannot be at the same time that another interval ends
* the ending of the interval for a pricing definition cannot be at the same time that another interval begins
* an pricing definition wuth an interval cannot be included (either paritally or fully) withing another pricing defition, except for the `default` interval.


## `priceable` Behavior
As soon as we are done with the `PricingDefinition` model we should move on and provide a way for assigning this functionallity to the resources of our application. This could be achieved by included module(s) that contain the functionallity to be shared. What we need is a the ability to assign priceable behavior to models with a class method like `priceable` (or so)

This could be achieved with a set of modules
* a `Pricing::Priceable::Behavior` module that contains the setup methods
* a `Pricing::Priceable::ClassMethods` methods needed for the priceable class
* a `Pricing::Priceable::InstanceMethods` methods needed for the priceable instances

Also when defining the behavior we would need to provide some options that will propagate to the `Pricing::Definition`associated models (and to the calculator later on) and will be used for (mostly) for validations by the `Pricing::Calculator`.

The options will be the following:

* **addon:** boolean, default `false`
* **for:** associate with primary priceable if `addon: true`
* **min:** minimum priceable capacity, Symbol, delegate to host model attribute
* **max:** minimum priceable capacity, delegate to host model attribute
* **seasonal:** boolean, default `true`, should include seasonal functionallity or not

Showcasing our application, the `Tour` and `PriceAddon` models could look like this:

```ruby
class Tour
  priceable min: :min_people, max: :max_people, seasonal: true
end

class PriceAddon
  priceable addon: true, for: :tour, min: :min_people, max: :max_people
  delegate :min_people, :max_people, to: :tour
end
```

And a quick draft of how the rest of the code would look like:

```ruby
module Pricing
    module Priceable
      module Behaviour
        def priceable(options = {})
          setup_priceable_options!(options)
          setup_priceable_associations!
        end
          
        def setup_priceable_associations!
          has_many :pricing_definitions, dependent: destroy, as: :priceable
        end
    
        def setup_priceable_options!
          # Do stuff here and raise if something goes bad
        end
      end
    end
  end

  module Priceable
    def self.included(klass)
      klass.include InstanceMethods::Base
      klass.include InstanceMethods::Seasonal
      klass.extend ClassMethods::Seasonal
      klass.extend ClassMethods::Base
    end

    module InstanceMethods
      module Base
        # ...
      end
      
      module Seasonal
        # ...
      end
    end

    module ClassMethods
      module Seasonal
        # ...
      end
    end
  end
end
```
