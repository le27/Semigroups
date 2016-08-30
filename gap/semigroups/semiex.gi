#############################################################################
##
#W  examples.gi
#Y  Copyright (C) 2013-15                                 James D. Mitchell
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

#for testing purposes

# BlocksOfPartition := function(partition)
#   local blocks, lookup, n, i, j;
#
#   blocks := []; lookup := []; n := 0;
#   for i in [1 .. Length(partition)] do
#     blocks[i] := [n + 1 .. partition[i] + n];
#     for j in blocks[i] do
#       lookup[j] := i;
#     od;
#     n := n + partition[i];
#   od;
#   return [blocks, lookup];
# end;
#
# IsEndomorphismOfPartition := function(bl, f)
#   local imblock, x;
#
#   for x in bl[1] do #blocks
#     imblock := bl[1][bl[2][x[1] ^ f]];
#     if not ForAll(x, y -> y ^ f in imblock) then
#       return false;
#     fi;
#   od;
#   return true;
# end;
#
# NrEndomorphismsPartition := function(partition)
#   local bl;
#   bl := BlocksOfPartition(partition);
#   return Number(FullTransformationSemigroup(Sum(partition)), x ->
#     IsEndomorphismOfPartition(bl, x));
# end;

# From the `The rank of the semigroup of transformations stabilising a
# partition of a finite set', by Araujo, Bentz, Mitchell, and Schneider (2014).

InstallMethod(EndomorphismsPartition, "for a list of positive integers",
[IsCyclotomicCollection],
function(partition)
  local s, r, distinct, equal, prev, n, blocks, unique, didprevrepeat, gens, x,
  m, y, w, p, i, j, k, block;

  if not ForAll(partition, IsPosInt) then
    ErrorNoReturn("Semigroups: EndomorphismsPartition: usage,\n",
                  "the argument <partition> must be a list of positive ",
                  "integers,");
  elif ForAll(partition, x -> x = 1) then
    return FullTransformationMonoid(Length(partition));
  elif Length(partition) = 1 then
    return FullTransformationMonoid(partition[1]);
  fi;

  if not IsSortedList(partition) then
    partition := ShallowCopy(partition);
    Sort(partition);
  fi;

  # preprocessing...

  s := 0;         # nr of distinct block sizes
  r := 0;         # nr of block sizes with at least one other block of equal
                  # size
  distinct := []; # indices of blocks with distinct block sizes
  equal := [];    # indices of blocks with at least one other block of equal
                  # size, partitioned according to the sizes of the blocks
  prev := 0;      # size of the previous block
  n := 0;         # the degree of the transformations
  blocks := [];   # the actual blocks of the partition
  unique := [];   # blocks of a unique size

  for i in [1 .. Length(partition)] do
    blocks[i] := [n + 1 .. partition[i] + n];
    n := n + partition[i];
    if partition[i] > prev then
      s := s + 1;
      distinct[s] := i;
      prev := partition[i];
      didprevrepeat := false;
      AddSet(unique, i);
    elif not didprevrepeat then
      # repeat block size
      r := r + 1;
      equal[r] := [i - 1, i];
      didprevrepeat := true;
      RemoveSet(unique, i - 1);
    else
      Add(equal[r], i);
    fi;
  od;

  # get the generators of T(X,P) over Sigma(X,P)...
  # from the proof of Theorem 3.3
  gens := [];
  for i in [1 .. Length(distinct) - 1] do
    for j in [i + 1 .. Length(distinct)] do
      x := [1 .. n];
      for k in [1 .. Length(blocks[distinct[i]])] do
        x[blocks[distinct[i]][k]] := blocks[distinct[j]][k];
      od;
      Add(gens, Transformation(x));
    od;
  od;

  for block in equal do
    x := [1 .. n];
    x{blocks[block[1]]} := blocks[block[2]];
    Add(gens, Transformation(x));
  od;

  # get the generators of Sigma(X,P) over S(X,P)...

  # the generators from B (swap blocks of adjacent distinct sizes)...
  for i in [1 .. s - 1] do
    x := [1 .. n];
    # map up
    for j in [1 .. Length(blocks[distinct[i]])] do
      x[blocks[distinct[i]][j]] := blocks[distinct[i + 1]][j];
      x[blocks[distinct[i + 1]][j]] := blocks[distinct[i]][j];
    od;
    # map down
    for j in [Length(blocks[distinct[i]]) + 1 ..
              Length(blocks[distinct[i + 1]])] do
      x[blocks[distinct[i + 1]][j]] := blocks[distinct[i]][1];
    od;
    Add(gens, Transformation(x));
  od;

  # the generators from C...
  if Length(blocks[distinct[1]]) <> 1 then
    x := [1 .. n];
    x[1] := 2;
    Add(gens, Transformation(x));
  fi;

  for i in [2 .. s] do
    if Length(blocks[distinct[i]]) - Length(blocks[distinct[i - 1]]) > 1 then
      x := [1 .. n];
      x[blocks[distinct[i]][1]] := x[blocks[distinct[i]][2]];
      Add(gens, Transformation(x));
    fi;
  od;

  # get the generators of S(X,P)...
  if s = r or s - r >= 2 then
    # 2 generators for the r wreath products of symmetric groups
    for i in [1 .. r] do
      m := Length(equal[i]);       #WreathProduct(S_n, S_m) m blocks of size n
      n := partition[equal[i][1]];
      x := blocks{equal[i]};

      if n > 1 then
        x[2] := Permuted(x[2], (1, 2));
      fi;

      if IsOddInt(m) or IsOddInt(n) then
        x := Permuted(x, PermList(Concatenation([2 .. m], [1])));
      else
        x := Permuted(x, PermList(Concatenation([1], [3 .. m], [2])));
      fi;

      x := MappingPermListList(Concatenation(blocks{equal[i]}),
                               Concatenation(x));
      Add(gens, AsTransformation(x));

      y := blocks{equal[i]};
      y[1] := Permuted(y[1], PermList(Concatenation([2 .. n], [1])));
      y := Permuted(y, (1, 2));
      y := MappingPermListList(Concatenation(blocks{equal[i]}),
                               Concatenation(y));
      Add(gens, AsTransformation(y));
    od;
  elif s - r = 1 and r >= 1 then
    #JDM this case should be changed as in the previous case
    # 2 generators for the r-1 wreath products of symmetric groups
    for i in [1 .. r - 1] do
      m := Length(equal[i]);       #WreathProduct(S_n, S_m) m blocks of size n
      n := partition[equal[i][1]];
      x := blocks{equal[i]};

      if n > 1 then
        x[2] := Permuted(x[2], (1, 2));
      fi;

      if IsOddInt(m) or IsOddInt(n) then
        x := Permuted(x, PermList(Concatenation([2 .. m], [1])));
      else
        x := Permuted(x, PermList(Concatenation([1], [3 .. m], [2])));
      fi;

      x := MappingPermListList(Concatenation(blocks{equal[i]}),
                               Concatenation(x));
      Add(gens, AsTransformation(x));

      y := blocks{equal[i]};
      y[1] := Permuted(y[1], PermList(Concatenation([2 .. n], [1])));
      y := Permuted(y, (1, 2));
      y := MappingPermListList(Concatenation(blocks{equal[i]}),
                               Concatenation(y));
      Add(gens, AsTransformation(y));
    od;

    # 3 generators for (S_{n_k}wrS_{m_k})\times S_{l_1}
    m := Length(equal[r]);
    n := partition[equal[r][1]];
    if IsOddInt(m) or IsOddInt(n) then
      x := Permuted(blocks{equal[r]}, PermList(Concatenation([2 .. m], [1])));
    else
      x := Permuted(blocks{equal[r]},
                    PermList(Concatenation([1], [3 .. m], [2])));
    fi;

    if n > 1 then
      x[2] := Permuted(x[2], (1, 2));
    fi;
    x := MappingPermListList(Concatenation(blocks{equal[r]}),
                             Concatenation(x));
    Add(gens, AsTransformation(x)); # (x, id)=u in the paper

    y := Permuted(blocks{equal[r]}, (1, 2));
    y[1] := Permuted(y[1], PermList(Concatenation([2 .. n], [1])));
    y := MappingPermListList(Concatenation(blocks{equal[r]}),
                             Concatenation(y));
    # (y, (1,2,\ldots, l_1))=v in the paper
    y := y * MappingPermListList(blocks[unique[1]],
                                 Concatenation(blocks[unique[1]]{[2 ..
                                               Length(blocks[unique[1]])]},
                                               [blocks[unique[1]][1]]));
    Add(gens, AsTransformation(y));

    if Length(blocks[unique[1]]) > 1 then
      w := MappingPermListList(blocks[unique[1]],
                               Permuted(blocks[unique[1]], (1, 2)));
      Add(gens, AsTransformation(w)); # (id, (1,2))=w in the paper
    fi;
  fi;
  if s - r >= 2 then # the (s-r) generators of W_2 in the proof
    for i in [1 .. s - r - 1] do
      if Length(blocks[unique[i]]) <> 1 then
        x := Permuted(blocks[unique[i]], (1, 2));
      else
        x := ShallowCopy(blocks[unique[i]]);
      fi;
      if IsOddInt(Length(blocks[unique[i + 1]])) then
        p := PermList(Concatenation([2 .. Length(blocks[unique[i + 1]])],
                                    [1]));
        Append(x, Permuted(blocks[unique[i + 1]], p));
      else

        p := PermList(Concatenation([1], [3 .. Length(blocks[unique[i + 1]])],
                                    [2]));
        Append(x, Permuted(blocks[unique[i + 1]], p));
      fi;
      x := MappingPermListList(Union(blocks[unique[i]],
                                     blocks[unique[i + 1]]), x);
      if x <> () then
        Add(gens, AsTransformation(x));
      fi;
    od;

    x := [];
    if partition[unique[1]] <> 1 then
      if IsOddInt(partition[unique[1]]) then
        # gaplint: ignore 3 FIXME
        Append(x, Permuted(blocks[unique[1]],
                           PermList(Concatenation([2 ..
                           Length(blocks[unique[1]])], [1]))));
      else
        # gaplint: ignore 3 FIXME
        Append(x, Permuted(blocks[unique[1]],
                           PermList(Concatenation([1],
                           [3 .. Length(blocks[unique[1]])], [2]))));
      fi;
    else
      Append(x, blocks[unique[1]]);
    fi;
    Append(x, Permuted(blocks[unique[s - r]], (1, 2)));
    x := MappingPermListList(Concatenation(blocks[unique[1]],
                                           blocks[unique[s - r]]), x);
    Add(gens, AsTransformation(x));
  fi;

  return Semigroup(gens);
end);

# Matrix semigroups . . .

InstallMethod(SEMIGROUPS_MatrixSemigroupConstructor,
"for a function, args, view string, print string",
[IsFunction, IsList, IsString, IsString],
function(func, args, view, print)
  local d, q, e, gens, x, S;

  if Length(args) = 2 then
    d := args[1];
    q := args[2];
    print := Concatenation(print, "(", String(d), ", ", String(q), ")");
  elif Length(args) = 3 then
    e := args[1];
    d := args[2];
    q := args[3];
    print := Concatenation(print, "(", String(e), ", ", String(d), ", ",
                           String(q), ")");
  else
    ErrorNoReturn("Semigroups: SEMIGROUPS_MatrixSemigroupConstructor:",
                  " usage,\nthere should be 2 or 3 arguments,");
  fi;
  gens := GeneratorsOfGroup(CallFuncList(func, args));
  x := OneMutable(gens[1]);
  x[d][d] := Z(q) * 0;
  gens := List(gens, x ->
               NewMatrixOverFiniteField(IsPlistMatrixOverFiniteFieldRep,
                                        GF(q),
                                        x));
  Add(gens, AsMatrix(IsMatrixOverFiniteField, gens[1], x));
  S := Monoid(gens);
  SetSEMIGROUPS_MatrixSemigroupViewString(S, view);
  SetSEMIGROUPS_MatrixSemigroupPrintString(S, print);
  return S;
end);

# FIXME remove this, there must be another method elsewhere for this, i.e. for
# matrices over semirings.

InstallMethod(PrintString,
"for a matrix semigroup with print string attribute",
[IsMatrixOverFiniteFieldSemigroup and HasGeneratorsOfSemigroup
 and HasSEMIGROUPS_MatrixSemigroupPrintString],
SEMIGROUPS_MatrixSemigroupPrintString);

#TODO ViewString
# FIXME remove this, there must be another method elsewhere for this, i.e. for
# matrices over semirings.

InstallMethod(ViewObj,
"for a matrix semigroup with view string attribute",
[IsMatrixOverFiniteFieldSemigroup and HasGeneratorsOfSemigroup
 and HasSEMIGROUPS_MatrixSemigroupViewString],
function(S)
  local n;
  Print("<");
  Print(SEMIGROUPS_MatrixSemigroupViewString(S));
  Print(" monoid ");
  n := DegreeOfMatrixSemigroup(S);
  Print(n, "x", n, " over ", BaseDomain(S));
  Print(">");
end);

# The full matrix semigroup is generated by a generating set
# for the general linear group plus one element of rank n-1

InstallMethod(GeneralLinearSemigroup, "for 2 pos ints",
[IsPosInt, IsPosInt],
function(d, q)
  local S;
  S := SEMIGROUPS_MatrixSemigroupConstructor(GL,
                                             [d, q],
                                             "general linear",
                                             "GLS");
  SetSize(S, q ^ (d * d));
  SetIsGeneralLinearSemigroup(S, true);
  SetIsRegularSemigroup(S, true);
  return S;
end);

InstallMethod(IsFullMatrixSemigroup, "for a semigroup",
[IsSemigroup], ReturnFalse);

InstallMethod(SpecialLinearSemigroup, "for pos int and pos int",
[IsPosInt, IsPosInt],
function(d, q)
  return SEMIGROUPS_MatrixSemigroupConstructor(SL,
                                               [d, q],
                                               "special linear",
                                               "SLS");
end);

#JDM method for IsFullMatrixSemigroup for a matrix semigroup

InstallMethod(MunnSemigroup, "for a semilattice", [IsSemigroup],
function(S)
  return InverseSemigroup(GeneratorsOfMunnSemigroup(S), rec(small := true));
end);

InstallMethod(GeneratorsOfMunnSemigroup, "for a semilattice", [IsSemigroup],
function(S)
  local po, au, id, su, gr, out, e, map, p, min, pos, x, i, j, k;

  if not IsSemilattice(S) then
    ErrorNoReturn("Semigroups: GeneratorsOfMunnSemigroup: usage,\n",
                  "the argument must be a semilattice");
  fi;

  po := DigraphReflexiveTransitiveClosure(Digraph(PartialOrderOfDClasses(S)));
  au := []; # automorphism groups partitions by size
  id := []; # ideals (as sets of indices) partitioned by size
  su := []; # induced subdigraphs corresponding to ideals

  for x in OutNeighbors(po) do
    gr := InducedSubdigraph(po, x);
    if not IsBound(au[Length(x)]) then
      au[Length(x)] := [];
      id[Length(x)] := [];
      su[Length(x)] := [];
    fi;
    Add(au[Length(x)], AutomorphismGroup(gr)
                       ^ MappingPermListList(DigraphVertices(gr), x));
    Add(id[Length(x)], x);
    Add(su[Length(x)], gr);
  od;

  out := [PartialPerm(id[Length(id)][1], id[Length(id)][1])];

  for i in [Length(id), Length(id) - 1 .. 3] do
    if not IsBound(id[i]) then
      continue;
    fi;
    for j in [1 .. Length(id[i])] do
      e := PartialPermNC(id[i][j], id[i][j]);
      for p in GeneratorsOfGroup(au[i][j]) do
        Add(out, e * p);
      od;
      for k in [j + 1 .. Length(id[i])] do
        map := IsomorphismDigraphs(su[i][j], su[i][k]);
        if map <> fail then
          p := MappingPermListList(id[i][j], DigraphVertices(su[i][j]))
                 * map * MappingPermListList(DigraphVertices(su[i][k]),
                                             id[i][k]);
          Add(out, e * p);
        fi;
      od;
    od;
  od;

  min := id[1][1][1]; # the index of the element in the minimal ideal
  Add(out, PartialPermNC([min], [min]));

  # All ideals of size 2 are isomorphic and have trivial automorphism group
  for j in [1 .. Length(id[2])] do
    e := PartialPermNC(id[2][j], id[2][j]);
    Add(out, e);
    pos := Position(id[2][j], min);
    for k in [j + 1 .. Length(id[2])] do
      if Position(id[2][k], min) = pos then
        Add(out, PartialPermNC(id[2][j], id[2][k]));
      else
        Add(out, PartialPermNC(id[2][j], Reversed(id[2][k])));
      fi;
    od;
  od;

  return out;
end);

InstallMethod(OrderEndomorphisms, "for a positive integer",
[IsPosInt],
function(n)
  local gens, S, i;

  gens := EmptyPlist(n);
  gens[1] := Transformation(Concatenation([1], [1 .. n - 1]));

  for i in [1 .. n - 1] do
    gens[i + 1] := [1 .. n];
    gens[i + 1][i] := i + 1;
    gens[i + 1] := TransformationNC(gens[i + 1]);
  od;

  S := Monoid(gens);
  SetIsRegularSemigroup(S, true);
  return S;
end);

InstallMethod(PartialTransformationMonoid, "for a positive integer",
[IsPosInt],
function(n)
  local a, b, c, d, S;

  a := [2, 1];
  b := [0 .. n - 1];
  b[1] := n;
  c := [1 .. n + 1];
  c[1] := n + 1;     # partial
  d := [2, 2];

  if n = 1 then
    S := Monoid(TransformationNC(c));
  elif n = 2 then
    S := Monoid(List([a, c, d], TransformationNC));
  else
    S := Monoid(List([a, b, c, d], TransformationNC));
  fi;

  SetIsRegularSemigroup(S, true);
  return S;
end);

InstallMethod(CatalanMonoid, "for a positive integer",
[IsPosInt],
function(n)
  local gens, next, i;

  if n = 1 then
    return Monoid(IdentityTransformation);
  fi;

  gens := [];

  for i in [1 .. n - 1] do
    next := [1 .. n];
    next[i + 1] := i;
    Add(gens, Transformation(next));
  od;

  return Monoid(gens, rec(generic := true));
end);

InstallMethod(PartitionMonoid, "for an integer",
[IsInt],
function(n)
  local gens, M;

  if n < 0 then
    ErrorNoReturn("Semigroups: PartitionMonoid: usage,\n",
                  "the argument <n> must be a non-negative integer,");
  elif n = 0 then
    return Monoid(Bipartition([]));
  elif n = 1 then
    return Monoid(Bipartition([[1], [-1]]));
  fi;

  gens := List(GeneratorsOfGroup(SymmetricGroup(n)), x -> AsBipartition(x, n));
  Add(gens, AsBipartition(PartialPermNC([2 .. n], [2 .. n]), n));
  Add(gens, Bipartition(Concatenation([[1, 2, -1, -2]],
                                        List([3 .. n], x -> [x, -x]))));

  M := Monoid(gens);
  SetIsRegularSemigroup(M, true);
  SetIsStarSemigroup(M, true);
  SetSize(M, Bell(2 * n));
  return M;
end);

InstallMethod(DualSymmetricInverseMonoid, "for an integer", [IsInt],
function(n)
  local gens;

  if n < 0 then
    ErrorNoReturn("Semigroups: DualSymmetricInverseMonoid: usage,\n",
                  "the argument <n> must be a non-negative integer,");
  elif n = 0 then
    return Monoid(Bipartition([]));
  elif n = 1 then
    return Monoid(Bipartition([[1, -1]]));
  fi;

  gens := List(GeneratorsOfGroup(SymmetricGroup(n)), x -> AsBipartition(x, n));

  if n = 2 then
    Add(gens, Bipartition([[1, 2, -1, -2]]));
  else
    Add(gens, Bipartition(Concatenation([[1, 2, -3], [3, -1, -2]],
                                           List([4 .. n], x -> [x, -x]))));
  fi;
  return InverseMonoid(gens);
end);

InstallMethod(PartialDualSymmetricInverseMonoid, "for an integer", [IsInt],
function(n)
  local gens;

  if n < 0 then
    ErrorNoReturn("Semigroups: PartialDualSymmetricInverseMonoid: usage,\n",
                  "the argument <n> must be a non-negative integer,");
  elif n = 0 then
    return Monoid(Bipartition([]));
  elif n = 1 or n = 2 then
    return PartialUniformBlockBijectionMonoid(n);
  fi;

  gens := Set([PermList(Concatenation([2 .. n], [1])), (1, 2)]);
  gens := List(gens, x -> AsBipartition(x, n + 1));
  Add(gens, Bipartition(Concatenation([[1, 2, -3], [-1, -2, 3]],
                                      List([4 .. n + 1], x -> [x, -x]))));
  Add(gens, Bipartition(Concatenation([[1, n + 1, -1, - n - 1]],
                                        List([2 .. n], x -> [x, -x]))));
  return InverseMonoid(gens);
end);

InstallMethod(BrauerMonoid, "for an integer", [IsInt],
function(n)
  local gens, M;

  if n < 0 then
    ErrorNoReturn("Semigroups: BrauerMonoid: usage,\n",
                  "the argument <n> must be a non-negative integer,");
  elif n = 0 then
    return Monoid(Bipartition([]));
  elif n = 1 then
    return Monoid(Bipartition([[1, -1]]));
  fi;

  gens := List(GeneratorsOfGroup(SymmetricGroup(n)), x -> AsBipartition(x, n));
  Add(gens, Bipartition(Concatenation([[1, 2]],
                                        List([3 .. n],
                                             x -> [x, -x]), [[-1, -2]])));
  M := Monoid(gens);
  SetIsRegularSemigroup(M, true);
  SetIsStarSemigroup(M, true);
  return M;
end);

InstallMethod(PartialBrauerMonoid, "for an integer", [IsInt],
function(n)
  local S;

  if n < 0 then
    ErrorNoReturn("Semigroups: PartialBrauerMonoid: usage,\n",
                  "the argument <n> must be a non-negative integer,");
  fi;

  S := Semigroup(BrauerMonoid(n),
                 AsSemigroup(IsBipartitionSemigroup,
                             SymmetricInverseMonoid(n)));
  SetIsRegularSemigroup(S, true);
  SetIsStarSemigroup(S, true);
  return S;
end);

InstallMethod(JonesMonoid, "for an integer",
[IsInt],
function(n)
  local gens, next, i, j, M;

  if n < 0 then
    ErrorNoReturn("Semigroups: JonesMonoid: usage,\n",
                  "the argument <n> must be a non-negative integer,");
  elif n = 0 then
    return Monoid(Bipartition([]));
  elif n = 1 then
    return Monoid(Bipartition([[1, -1]]));
  fi;

  gens := [];
  for i in [1 .. n - 1] do
    next := [[i, i + 1], [-i, -i - 1]];
    for j in [1 .. i - 1] do
      Add(next, [j, -j]);
    od;
    for j in [i + 2 .. n] do
      Add(next, [j, -j]);
    od;
    Add(gens, Bipartition(next));
  od;

  M := Monoid(gens);
  SetIsRegularSemigroup(M, true);
  SetIsStarSemigroup(M, true);
  return M;
end);

InstallMethod(AnnularJonesMonoid, "for an integer", [IsInt],
function(n)
  local p, M;

  if n < 0 then
    ErrorNoReturn("Semigroups: AnnularJonesMonoid: usage,\n",
                  "the argument <n> must be a non-negative integer,");
  elif n = 0 or n = 1 then
    return JonesMonoid(n);
  fi;

  p := PermList(Concatenation([n], [1 .. n - 1]));
  M := Monoid(JonesMonoid(n), AsBipartition(p));
  SetIsRegularSemigroup(M, true);
  SetIsStarSemigroup(M, true);
  return M;
end);

InstallMethod(PartialJonesMonoid, "for an integer",
[IsInt],
function(n)
  local gens, next, i, j, M;

  if n < 0 then
    ErrorNoReturn("Semigroups: PartialJonesMonoid: usage,\n",
                  "the argument <n> must be a non-negative integer,");
  elif n = 0 then
    return Monoid(Bipartition([]));
  elif n = 1 then
    return Monoid(Bipartition([[1, -1]]), Bipartition([[1], [-1]]));
  fi;

  gens := ShallowCopy(GeneratorsOfMonoid(JonesMonoid(n)));

  for i in [1 .. n] do
    next := [[i], [-i]];
    for j in [1 .. i - 1] do
      Add(next, [j, -j]);
    od;
    for j in [i + 1 .. n] do
      Add(next, [j, -j]);
    od;
    Add(gens, Bipartition(next));
  od;

  M := Monoid(gens);
  SetIsRegularSemigroup(M, true);
  SetIsStarSemigroup(M, true);
  return M;
end);

InstallMethod(MotzkinMonoid, "for an integer",
[IsInt],
function(n)
  local gens, M;

  if n < 0 then
    ErrorNoReturn("Semigroups: MotzkinMonoid: usage,\n",
                  "the argument <n> must be a non-negative integer,");
  elif n = 0 then
    return Monoid(Bipartition([]));
  fi;

  gens := List(GeneratorsOfInverseSemigroup(POI(n)),
               x -> AsBipartition(x, n));
  M := Monoid(JonesMonoid(n), gens);
  SetIsRegularSemigroup(M, true);
  SetIsStarSemigroup(M, true);
  return M;
end);

# TODO: document this!

InstallMethod(PartialJonesMonoid, "for a positive integer",
[IsPosInt],
function(n)
  return RegularSemigroup(JonesMonoid(n),
                          AsSemigroup(IsBipartitionSemigroup,
                                      Semigroup(Idempotents(POI(n)))));
end);

InstallMethod(POI, "for a positive integer", [IsPosInt],
function(n)
  local out, i;

  out := EmptyPlist(n);
  out[1] := PartialPermNC([0 .. n - 1]);
  if n = 1 then
    Add(out, PartialPermNC([1]));
  fi;
  for i in [0 .. n - 2] do
    out[i + 2] := [1 .. n];
    out[i + 2][(n - i) - 1] := n - i;
    out[i + 2][n - i] := 0;
    out[i + 2] := PartialPermNC(out[i + 2]);
  od;
  return InverseMonoid(out);
end);

InstallMethod(POPI, "for a positive integer", [IsPosInt],
function(n)
  if n = 1 then
    return InverseMonoid(PartialPerm([1]), PartialPerm([]));
  fi;
  return InverseMonoid(PartialPermNC(Concatenation([2 .. n], [1])),
                       PartialPermNC(Concatenation([1 .. n - 2], [n])));
end);

# TODO improve and document this
# FIXME this doesn't work

InstallMethod(PowerSemigroup, "for a group", [IsGroup],
function(g)
  local act, dom, gens, s, i, f;

  act := function(A, B)
    return Union(List(A, x -> x * B));
  end;
  dom := Combinations(Elements(g));
  Sort(dom, function(x, y)
              return Length(x) < Length(y);
            end);
  gens := [TransformationOp(dom[1], dom, act)];
  s := Semigroup(gens);
  i := 2;

  while Size(s) < 2 ^ Size(g) do
    i := i + 1;
    f := TransformationOp(dom[i], dom, act);
    s := ClosureSemigroup(s, f);
  od;
  return s;
end);

InstallMethod(PlanarUniformBlockBijectionMonoid, "for a positive integer",
[IsPosInt],
function(n)
  local gens, next, i, j;

  if n = 1 then
    return InverseMonoid(Bipartition([[1, -1]]));
  fi;

  gens := [];

  #(2,2)-transapsis generators
  for i in [1 .. n - 1] do
    next := [];
    for j in [1 .. i - 1] do
      next[j] := j;
      next[n + j] := j;
    od;
    next[i] := i;
    next[i + 1] := i;
    next[i + n] := i;
    next[i + n + 1] := i;
    for j in [i + 2 .. n] do
      next[j] := j - 1;
      next[n + j] := j - 1;
    od;
    gens[i] := BipartitionByIntRep(next);
  od;

  return InverseMonoid(gens);
end);

InstallMethod(UniformBlockBijectionMonoid, "for a positive integer",
[IsPosInt],
function(n)
  local gens;
  if n = 1 then
    return InverseMonoid(Bipartition([[1, -1]]));
  fi;

  gens := List(GeneratorsOfGroup(SymmetricGroup(n)), x -> AsBipartition(x, n));
  Add(gens, Bipartition(Concatenation([[1, 2, -1, -2]],
                                        List([3 .. n], x -> [x, -x]))));
  return InverseMonoid(gens);
end);

InstallMethod(PartialUniformBlockBijectionMonoid, "for a positive integer",
[IsPosInt],
function(n)
  local gens;
  if n = 1 then
    return InverseMonoid(Bipartition([[1, -1], [2, -2]]),
                         Bipartition([[1, 2, -1, -2]]));
  fi;

  gens := Set([PermList(Concatenation([2 .. n], [1])), (1, 2)]);
  gens := List(gens, x -> AsBipartition(x, n + 1));
  Add(gens, Bipartition(Concatenation([[1, 2, -1, -2]],
                                        List([3 .. n + 1], x -> [x, -x]))));
  Add(gens, Bipartition(Concatenation([[1, n + 1, -1, - n - 1]],
                                        List([2 .. n], x -> [x, -x]))));
  return InverseMonoid(gens);
end);

InstallMethod(RookPartitionMonoid, "for a positive integer", [IsPosInt],
function(n)
  local S;
  S := Monoid(PartialUniformBlockBijectionMonoid(n), 
               Bipartition(Concatenation([[1], [-1]],
                                         List([2 .. n + 1], x -> [x, -x]))));
  SetIsRegularSemigroup(S, true);
  SetIsStarSemigroup(S, true);
  return S;
end);


InstallMethod(ApsisMonoid,
"for a positive integer and positive integer",
[IsPosInt, IsPosInt],
function(m, n)
  local gens, next, S, b, i, j;

  if n = 1 and m = 1 then
    return InverseMonoid(Bipartition([[1], [-1]]));
  fi;

  gens := [];

  if n < m then
    next := [];

    #degree k identity bipartition
    for i in [1 .. n] do
      next[i] := i;
      next[n + i] := i;
    od;
    gens[1] := BipartitionByIntRep(next);
    S := InverseMonoid(gens);
    SetIsRegularSemigroup(S, true);
    SetIsStarSemigroup(S, true);
    return S;
  fi;

  #m-apsis generators
  for i in [1 .. n - m + 1] do
    next := [];
    b := 1;

    for j in [1 .. i - 1] do
      next[j] := b;
      next[n + j] := b;
      b := b + 1;
    od;

    for j in [i .. i + m - 1] do
      next[j] := b;
    od;
    b := b + 1;

    for j in [i + m .. n] do
      next[j] := b;
      next[n + j] := b;
      b := b + 1;
    od;

    for j in [i .. i + m - 1] do
      next[n + j] := b;
    od;

    gens[i] := BipartitionByIntRep(next);
  od;

  S := Monoid(gens);
  SetIsRegularSemigroup(S, true);
  SetIsStarSemigroup(S, true);
  return S;
end);

InstallMethod(CrossedApsisMonoid,
"for a positive integer and positive integer",
[IsPosInt, IsPosInt],
function(m, n)
  local gens, S;

  if n = 1 then
    if m = 1 then
      return InverseMonoid(Bipartition([[1], [-1]]));
    else
      return InverseMonoid(Bipartition([[1, -1]]));
    fi;
  fi;

  gens := List(GeneratorsOfGroup(SymmetricGroup(n)), x -> AsBipartition(x, n));
  if m <= n then
    Add(gens, Bipartition(Concatenation([[1 .. m]],
                                          List([m + 1 .. n],
                                               x -> [x, -x]), [[-m .. -1]])));
  fi;

  S := Monoid(gens);
  SetIsRegularSemigroup(S, true);
  SetIsStarSemigroup(S, true);
  return S;
end);

InstallMethod(PlanarModularPartitionMonoid,
"for a positive integer and positive integer",
[IsPosInt, IsPosInt],
function(m, n)
  local gens, next, b, S, i, j;

  if n < m then
    return PlanarUniformBlockBijectionMonoid(n);
  elif n = 1 then
    return InverseMonoid(Bipartition([[1], [-1]]));
  fi;

  gens := [];

  #(2,2)-transapsis generators
  for i in [1 .. n - 1] do
    next := [];
    for j in [1 .. i - 1] do
      next[j] := j;
      next[n + j] := j;
    od;
    next[i] := i;
    next[i + 1] := i;
    next[i + n] := i;
    next[i + n + 1] := i;
    for j in [i + 2 .. n] do
      next[j] := j - 1;
      next[n + j] := j - 1;
    od;
    gens[i] := BipartitionByIntRep(next);
  od;

  #m-apsis generators
  for i in [1 .. n - m + 1] do
    next := [];
    b := 1;

    for j in [1 .. i - 1] do
      next[j] := b;
      next[n + j] := b;
      b := b + 1;
    od;

    for j in [i .. i + m - 1] do
      next[j] := b;
    od;
    b := b + 1;

    for j in [i + m .. n] do
      next[j] := b;
      next[n + j] := b;
      b := b + 1;
    od;

    for j in [i .. i + m - 1] do
      next[n + j] := b;
    od;

    gens[n - 1 + i] := BipartitionByIntRep(next);
  od;

  S := Monoid(gens);
  SetIsRegularSemigroup(S, true);
  SetIsStarSemigroup(S, true);
  return S;
end);

InstallMethod(PlanarPartitionMonoid,
"for a positive integer",
[IsPosInt],
function(n)
  return PlanarModularPartitionMonoid(1, n);
end);

InstallMethod(ModularPartitionMonoid,
"for a positive integer and positive integer",
[IsPosInt, IsPosInt],
function(m, n)
  local gens, S;

  if n = 1 then
    return InverseMonoid(Bipartition([[1], [-1]]));
  fi;

  gens := List(GeneratorsOfGroup(SymmetricGroup(n)), x -> AsBipartition(x, n));
  Add(gens, Bipartition(Concatenation([[1, 2, -1, -2]],
                                        List([3 .. n], x -> [x, -x]))));
  if m <= n then
    Add(gens, Bipartition(Concatenation([[1 .. m]],
                                          List([m + 1 .. n],
                                               x -> [x, -x]), [[-m .. -1]])));
  fi;
  S := Monoid(gens);
  SetIsRegularSemigroup(S, true);
  SetIsStarSemigroup(S, true);
  return S;
end);

InstallMethod(SingularPartitionMonoid, "for a positive integer",
[IsPosInt],
function(n)
  local blocks, i;

  if n = 1 then
    return SemigroupIdeal(PartitionMonoid(1), Bipartition([[1], [-1]]));
  fi;

  blocks := [[1, 2, -1, -2]];
  for i in [3 .. n] do
    blocks[i - 1] := [i, -i];
  od;
  return SemigroupIdeal(PartitionMonoid(n), Bipartition(blocks));
end);

InstallMethod(SingularTransformationSemigroup, "for a positive integer",
[IsPosInt],
function(n)
  local x, S;
  if n = 1 then
    ErrorNoReturn("Semigroups: SingularTransformationSemigroup: usage,\n",
                  "the argument must be greater than 1,");
  fi;
  x := TransformationNC(Concatenation([1 .. n - 1], [n - 1]));
  S := FullTransformationSemigroup(n);
  return SemigroupIdeal(S, x);
end);

# TODO document this

InstallMethod(SingularOrderEndomorphisms, "for a positive integer",
[IsPosInt],
function(n)
  local x, S;
  if n = 1 then
    ErrorNoReturn("Semigroups: SingularOrderEndomorphisms: usage,\n",
                  "the argument must be greater than 1,");
  fi;
  x := TransformationNC(Concatenation([1 .. n - 1], [n - 1]));
  S := OrderEndomorphisms(n);
  return SemigroupIdeal(S, x);
end);

InstallMethod(SingularBrauerMonoid, "for a positive integer",
[IsPosInt],
function(n)
  local blocks, x, S, i;

  if n = 1 then
    ErrorNoReturn("Semigroups: SingularBrauerMonoid: usage,\n",
                  "the argument must be greater than 1,");
  fi;

  blocks := [[1, 2], [-1, -2]];
  for i in [3 .. n] do
    blocks[i] := [i, -i];
  od;
  x := Bipartition(blocks);
  S := BrauerMonoid(n);
  return SemigroupIdeal(S, x);
end);

InstallMethod(SingularJonesMonoid, "for a positive integer",
[IsPosInt],
function(n)
  local blocks, x, S, i;
  if n = 1 then
    ErrorNoReturn("Semigroups: SingularJonesMonoid: usage,\n",
                  "the argument must be greater than 1,");
  fi;

  blocks := [[1, 2], [-1, -2]];
  for i in [3 .. n] do
    blocks[i] := [i, -i];
  od;
  x := Bipartition(blocks);
  S := JonesMonoid(n);
  return SemigroupIdeal(S, x);
end);

InstallMethod(SingularDualSymmetricInverseMonoid, "for a positive integer",
[IsPosInt],
function(n)
  local blocks, x, S, i;
  if n = 1 then
    ErrorNoReturn("Semigroups: SingularDualSymmetricInverseMonoid: usage,\n",
                  "the argument must be greater than 1,");
  fi;

  blocks := [[1, 2, -1, -2]];
  for i in [3 .. n] do
    blocks[i - 1] := [i, -i];
  od;
  x := Bipartition(blocks);
  S := DualSymmetricInverseMonoid(n);
  return SemigroupIdeal(S, x);
end);

InstallMethod(SingularPlanarUniformBlockBijectionMonoid,
"for a positive integer", [IsPosInt],
function(n)
  local blocks, x, S, i;
  if n = 1 then
    ErrorNoReturn("Semigroups: SingularPlanarUniformBlockBijectionMonoid:",
                  " usage,\nthe argument must be greater than 1,");
  fi;

  blocks := [[1, 2, -1, -2]];
  for i in [3 .. n] do
    blocks[i - 1] := [i, -i];
  od;

  x := Bipartition(blocks);
  S := PlanarUniformBlockBijectionMonoid(n);
  return SemigroupIdeal(S, x);
end);

InstallMethod(SingularUniformBlockBijectionMonoid,
"for a positive integer", [IsPosInt],
function(n)
  local blocks, x, S, i;
  if n = 1 then
    ErrorNoReturn("Semigroups: SingularUniformBlockBijectionMonoid:",
                  " usage,\nthe argument must be greater than 1,");
  fi;

  blocks := [[1, 2, -1, -2]];
  for i in [3 .. n] do
    blocks[i - 1] := [i, -i];
  od;

  x := Bipartition(blocks);
  S := UniformBlockBijectionMonoid(n);
  return SemigroupIdeal(S, x);
end);

InstallMethod(SingularApsisMonoid,
"for a positive integer and positive integer",
[IsPosInt, IsPosInt],
function(m, n)
  local blocks, x, S, i;
  if m > n then
    ErrorNoReturn("Semigroups: SingularApsisMonoid: usage,\n",
                  "the first argument must be less than or equal to the ",
                  "second argument,");
  fi;

  blocks := [[1 .. m], [-m .. -1]];
  for i in [m + 1 .. n] do
    blocks[i - m + 2] := [i, -i];
  od;

  x := Bipartition(blocks);
  S := ApsisMonoid(m, n);
  return SemigroupIdeal(S, x);
end);

InstallMethod(SingularCrossedApsisMonoid,
"for a positive integer and positive integer",
[IsPosInt, IsPosInt],
function(m, n)
  local blocks, x, S, i;
  if m > n then
    ErrorNoReturn("Semigroups: SingularCrossedApsisMonoid: usage,\n",
                  "the first argument must be less than or equal to ",
                  "the second argument,");
  fi;

  blocks := [[1 .. m], [-m .. -1]];
  for i in [m + 1 .. n] do
    blocks[i - m + 2] := [i, -i];
  od;

  x := Bipartition(blocks);
  S := CrossedApsisMonoid(m, n);
  return SemigroupIdeal(S, x);
end);

InstallMethod(SingularPlanarModularPartitionMonoid,
"for a positive integer and positive integer",
[IsPosInt, IsPosInt],
function(m, n)
  local blocks, x, S, i;
  if n = 1 then
    if m = 1 then
      return SemigroupIdeal(PlanarModularPartitionMonoid(1, 1),
                            Bipartition([[1], [-1]]));
    else
      ErrorNoReturn("Semigroups: SingularPlanarModularPartitionMonoid:",
                    " usage,\nthe second argument must be greater than 1",
                    " when the first argument is also greater than 1,");
    fi;
  fi;

  blocks := [[1, 2, -1, -2]];
  for i in [3 .. n] do
    blocks[i - 1] := [i, -i];
  od;

  x := Bipartition(blocks);
  S := PlanarModularPartitionMonoid(m, n);
  return SemigroupIdeal(S, x);
end);

InstallMethod(SingularPlanarPartitionMonoid, "for a positive integer",
[IsPosInt],
function(n)
  local blocks, x, S, i;
  if n = 1 then
    return SemigroupIdeal(PlanarPartitionMonoid(1), Bipartition([[1], [-1]]));
  fi;

  blocks := [[1, 2, -1, -2]];
  for i in [3 .. n] do
    blocks[i - 1] := [i, -i];
  od;

  x := Bipartition(blocks);
  S := PlanarPartitionMonoid(n);
  return SemigroupIdeal(S, x);
end);

InstallMethod(SingularModularPartitionMonoid,
"for a positive integer and positive integer",
[IsPosInt, IsPosInt],
function(m, n)
  local blocks, x, S, i;
  if n = 1 then
    if m = 1 then
      return SemigroupIdeal(ModularPartitionMonoid(1, 1),
                            Bipartition([[1], [-1]]));
    else
      ErrorNoReturn("Semigroups: SingularModularPartitionMonoid:",
                    " usage,\nthe second argument must be greater than 1",
                    " when the first argument is also greater than 1,");
    fi;
  fi;

  blocks := [[1, 2, -1, -2]];
  for i in [3 .. n] do
    blocks[i - 1] := [i, -i];
  od;

  x := Bipartition(blocks);
  S := ModularPartitionMonoid(m, n);
  return SemigroupIdeal(S, x);
end);
